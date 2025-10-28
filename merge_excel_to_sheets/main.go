package main

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/xuri/excelize/v2"
)

// FileFilter 文件过滤器接口，用于扩展过滤逻辑
type FileFilter interface {
	// ShouldInclude 判断是否应该包含该文件
	ShouldInclude(path string, info fs.FileInfo) bool
}

// SheetNamer Sheet 命名策略接口，用于扩展命名规则
type SheetNamer interface {
	// GetSheetName 根据文件路径获取 sheet 名称
	GetSheetName(filePath string, basePath string) string
}

// ExcelMerger Excel 合并器
type ExcelMerger struct {
	sourceDir   string
	outputPath  string
	filter      FileFilter
	namer       SheetNamer
	maxSheetLen int // Excel sheet 名称最大长度限制
}

// NewExcelMerger 创建新的 Excel 合并器
func NewExcelMerger(sourceDir, outputPath string, filter FileFilter, namer SheetNamer) *ExcelMerger {
	return &ExcelMerger{
		sourceDir:   sourceDir,
		outputPath:  outputPath,
		filter:      filter,
		namer:       namer,
		maxSheetLen: 31, // Excel sheet 名称最大长度
	}
}

// Merge 执行合并操作
func (em *ExcelMerger) Merge() error {
	// 创建输出 Excel 文件
	outputFile := excelize.NewFile()
	defer outputFile.Close()

	// 删除默认的 Sheet1
	outputFile.DeleteSheet("Sheet1")

	// 遍历源目录，查找所有 Excel 文件
	excelFiles, err := em.findExcelFiles()
	if err != nil {
		return fmt.Errorf("查找 Excel 文件失败: %w", err)
	}

	if len(excelFiles) == 0 {
		return fmt.Errorf("未找到符合条件的 Excel 文件")
	}

	// 用于跟踪 sheet 名称，避免重复
	sheetNameCount := make(map[string]int)

	// 处理每个 Excel 文件
	for _, filePath := range excelFiles {
		if err := em.mergeExcelFile(outputFile, filePath, sheetNameCount); err != nil {
			fmt.Printf("警告: 处理文件 %s 失败: %v\n", filePath, err)
			continue
		}
	}

	// 保存输出文件
	if err := outputFile.SaveAs(em.outputPath); err != nil {
		return fmt.Errorf("保存输出文件失败: %w", err)
	}

	fmt.Printf("成功合并 %d 个文件到 %s\n", len(excelFiles), em.outputPath)
	return nil
}

// findExcelFiles 查找所有符合条件的 Excel 文件
func (em *ExcelMerger) findExcelFiles() ([]string, error) {
	var excelFiles []string

	err := filepath.WalkDir(em.sourceDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if d.IsDir() {
			return nil
		}

		info, err := d.Info()
		if err != nil {
			return err
		}

		// 应用过滤器
		if em.filter != nil && !em.filter.ShouldInclude(path, info) {
			return nil
		}

		// 检查是否是 Excel 文件
		ext := strings.ToLower(filepath.Ext(path))
		if ext == ".xlsx" || ext == ".xlsm" || ext == ".xltx" || ext == ".xltm" {
			excelFiles = append(excelFiles, path)
		}

		return nil
	})

	return excelFiles, err
}

// mergeExcelFile 合并单个 Excel 文件的所有 sheet
func (em *ExcelMerger) mergeExcelFile(outputFile *excelize.File, filePath string, sheetNameCount map[string]int) error {
	// 打开源 Excel 文件
	sourceFile, err := excelize.OpenFile(filePath)
	if err != nil {
		return fmt.Errorf("打开文件失败: %w", err)
	}
	defer sourceFile.Close()

	// 获取源文件的所有 sheet
	sheetList := sourceFile.GetSheetList()

	// 遍历每个 sheet
	for _, sourceSheetName := range sheetList {
		// 生成目标 sheet 名称
		baseSheetName := em.namer.GetSheetName(filePath, em.sourceDir)
		targetSheetName := em.getUniqueSheetName(baseSheetName, sourceSheetName, sheetNameCount)

		// 复制 sheet（包括格式）
		if err := em.copySheetWithFormat(outputFile, sourceFile, sourceSheetName, targetSheetName); err != nil {
			return fmt.Errorf("复制 sheet %s 失败: %w", sourceSheetName, err)
		}

		fmt.Printf("  - 已复制: %s -> %s (来自 %s)\n", sourceSheetName, targetSheetName, filePath)
	}

	return nil
}

// copySheetWithFormat 复制 sheet 并保留格式
func (em *ExcelMerger) copySheetWithFormat(dstFile, srcFile *excelize.File, srcSheetName, dstSheetName string) error {
	// 创建新的 sheet
	index, err := dstFile.NewSheet(dstSheetName)
	if err != nil {
		return err
	}
	dstFile.SetActiveSheet(index)

	// 获取源 sheet 的所有行
	rows, err := srcFile.GetRows(srcSheetName)
	if err != nil {
		return err
	}

	// 复制样式映射
	styleMap := make(map[int]int)

	// 复制数据和格式
	for rowIdx, row := range rows {
		for colIdx, cellValue := range row {
			cellName, err := excelize.CoordinatesToCellName(colIdx+1, rowIdx+1)
			if err != nil {
				continue
			}

			// 设置单元格值
			dstFile.SetCellValue(dstSheetName, cellName, cellValue)

			// 复制单元格样式
			srcStyleID, err := srcFile.GetCellStyle(srcSheetName, cellName)
			if err == nil && srcStyleID != 0 {
				// 检查是否已经复制过该样式
				dstStyleID, exists := styleMap[srcStyleID]
				if !exists {
					// 获取源样式
					srcStyle, err := srcFile.GetStyle(srcStyleID)
					if err == nil && srcStyle != nil {
						// 在目标文件中创建新样式
						dstStyleID, err = dstFile.NewStyle(srcStyle)
						if err == nil {
							styleMap[srcStyleID] = dstStyleID
						}
					}
				}

				// 应用样式到目标单元格
				if dstStyleID != 0 {
					dstFile.SetCellStyle(dstSheetName, cellName, cellName, dstStyleID)
				}
			}
		}
	}

	// 复制列宽
	for colIdx := 0; colIdx < 100; colIdx++ { // 假设最多 100 列
		colName, _ := excelize.ColumnNumberToName(colIdx + 1)
		width, err := srcFile.GetColWidth(srcSheetName, colName)
		if err == nil && width > 0 {
			dstFile.SetColWidth(dstSheetName, colName, colName, width)
		}
	}

	// 复制行高
	for rowIdx := 1; rowIdx <= len(rows); rowIdx++ {
		height, err := srcFile.GetRowHeight(srcSheetName, rowIdx)
		if err == nil && height > 0 {
			dstFile.SetRowHeight(dstSheetName, rowIdx, height)
		}
	}

	// 复制合并单元格
	mergeCells, err := srcFile.GetMergeCells(srcSheetName)
	if err == nil {
		for _, mergeCell := range mergeCells {
			dstFile.MergeCell(dstSheetName, mergeCell.GetStartAxis(), mergeCell.GetEndAxis())
		}
	}

	return nil
}

// getUniqueSheetName 获取唯一的 sheet 名称
func (em *ExcelMerger) getUniqueSheetName(baseName, originalSheetName string, sheetNameCount map[string]int) string {
	// 如果基础名称为空，使用原始 sheet 名称
	if baseName == "" {
		baseName = originalSheetName
	}

	// 限制长度
	if len(baseName) > em.maxSheetLen {
		baseName = baseName[:em.maxSheetLen]
	}

	// 检查是否重复
	sheetName := baseName
	count, exists := sheetNameCount[baseName]
	if exists {
		count++
		sheetNameCount[baseName] = count
		// 添加后缀确保唯一性
		suffix := fmt.Sprintf("_%d", count)
		maxLen := em.maxSheetLen - len(suffix)
		if maxLen < 1 {
			maxLen = 1
		}
		if len(baseName) > maxLen {
			baseName = baseName[:maxLen]
		}
		sheetName = baseName + suffix
	} else {
		sheetNameCount[baseName] = 0
	}

	return sheetName
}

// ========== 内置过滤器实现 ==========

// DefaultFilter 默认过滤器，匹配所有 Excel 文件
type DefaultFilter struct{}

func (f *DefaultFilter) ShouldInclude(path string, info fs.FileInfo) bool {
	ext := strings.ToLower(filepath.Ext(path))
	return ext == ".xlsx" || ext == ".xlsm" || ext == ".xltx" || ext == ".xltm"
}

// ExtensionFilter 扩展名过滤器
type ExtensionFilter struct {
	Extensions []string // 允许的扩展名，如 [".xlsx", ".xlsm"]
}

func (f *ExtensionFilter) ShouldInclude(path string, info fs.FileInfo) bool {
	ext := strings.ToLower(filepath.Ext(path))
	for _, allowedExt := range f.Extensions {
		if ext == strings.ToLower(allowedExt) {
			return true
		}
	}
	return false
}

// PrefixFilter 文件名前缀过滤器
type PrefixFilter struct {
	Prefix string
}

func (f *PrefixFilter) ShouldInclude(path string, info fs.FileInfo) bool {
	name := info.Name()
	ext := strings.ToLower(filepath.Ext(name))
	if ext != ".xlsx" && ext != ".xlsm" && ext != ".xltx" && ext != ".xltm" {
		return false
	}
	return strings.HasPrefix(name, f.Prefix)
}

// PatternFilter 文件名模式过滤器（支持 * 通配符）
type PatternFilter struct {
	Pattern string
}

func (f *PatternFilter) ShouldInclude(path string, info fs.FileInfo) bool {
	name := info.Name()
	ext := strings.ToLower(filepath.Ext(name))
	if ext != ".xlsx" && ext != ".xlsm" && ext != ".xltx" && ext != ".xltm" {
		return false
	}
	matched, _ := filepath.Match(f.Pattern, name)
	return matched
}

// CompositeFilter 组合过滤器，支持多个过滤器的 AND/OR 组合
type CompositeFilter struct {
	Filters []FileFilter
	UseAND  bool // true: AND 组合, false: OR 组合
}

func (f *CompositeFilter) ShouldInclude(path string, info fs.FileInfo) bool {
	if len(f.Filters) == 0 {
		return true
	}

	if f.UseAND {
		for _, filter := range f.Filters {
			if !filter.ShouldInclude(path, info) {
				return false
			}
		}
		return true
	} else {
		for _, filter := range f.Filters {
			if filter.ShouldInclude(path, info) {
				return true
			}
		}
		return false
	}
}

// ========== 内置命名策略实现 ==========

// FirstLevelDirNamer 使用第一层目录名称作为 sheet 名称
type FirstLevelDirNamer struct{}

func (n *FirstLevelDirNamer) GetSheetName(filePath string, basePath string) string {
	// 获取相对路径
	relPath, err := filepath.Rel(basePath, filePath)
	if err != nil {
		// 如果无法获取相对路径，使用文件名
		return strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	}

	// 分割路径获取第一层目录
	parts := strings.Split(relPath, string(filepath.Separator))
	if len(parts) > 1 {
		return parts[0]
	}

	// 如果文件在根目录，使用文件名
	return strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
}

// FileNameNamer 使用文件名（不含扩展名）作为 sheet 名称
type FileNameNamer struct{}

func (n *FileNameNamer) GetSheetName(filePath string, basePath string) string {
	return strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
}

// FullPathNamer 使用完整相对路径作为 sheet 名称
type FullPathNamer struct {
	Separator string // 路径分隔符，默认为 "_"
}

func (n *FullPathNamer) GetSheetName(filePath string, basePath string) string {
	relPath, err := filepath.Rel(basePath, filePath)
	if err != nil {
		return strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
	}

	sep := n.Separator
	if sep == "" {
		sep = "_"
	}

	// 移除扩展名并替换路径分隔符
	relPath = strings.TrimSuffix(relPath, filepath.Ext(relPath))
	relPath = strings.ReplaceAll(relPath, string(filepath.Separator), sep)

	return relPath
}

// CustomNamer 自定义命名函数
type CustomNamer struct {
	NameFunc func(filePath string, basePath string) string
}

func (n *CustomNamer) GetSheetName(filePath string, basePath string) string {
	if n.NameFunc != nil {
		return n.NameFunc(filePath, basePath)
	}
	return strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))
}

// ========== 主函数示例 ==========

func main() {
	// 检查命令行参数
	if len(os.Args) < 3 {
		fmt.Println("使用方法:")
		fmt.Println("  merge_excel_to_sheets <源目录> <输出文件>")
		fmt.Println()
		fmt.Println("示例:")
		fmt.Println("  merge_excel_to_sheets ./data ./output/merged.xlsx")
		os.Exit(1)
	}

	sourceDir := os.Args[1]
	outputPath := os.Args[2]

	// 检查源目录是否存在
	if _, err := os.Stat(sourceDir); os.IsNotExist(err) {
		fmt.Printf("错误: 源目录不存在: %s\n", sourceDir)
		os.Exit(1)
	}

	// 确保输出目录存在
	outputDir := filepath.Dir(outputPath)
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		fmt.Printf("错误: 无法创建输出目录: %v\n", err)
		os.Exit(1)
	}

	// 创建过滤器和命名策略
	// 示例1: 使用默认过滤器和第一层目录命名
	filter := &DefaultFilter{}
	namer := &FirstLevelDirNamer{}

	// 示例2: 使用前缀过滤器
	// filter := &PrefixFilter{Prefix: "report"}

	// 示例3: 使用模式过滤器
	// filter := &PatternFilter{Pattern: "*.xlsx"}

	// 示例4: 使用组合过滤器
	// filter := &CompositeFilter{
	// 	Filters: []FileFilter{
	// 		&ExtensionFilter{Extensions: []string{".xlsx"}},
	// 		&PrefixFilter{Prefix: "data"},
	// 	},
	// 	UseAND: true,
	// }

	// 示例5: 使用文件名命名
	// namer := &FileNameNamer{}

	// 示例6: 使用完整路径命名
	// namer := &FullPathNamer{Separator: "-"}

	// 示例7: 使用自定义命名
	// namer := &CustomNamer{
	// 	NameFunc: func(filePath string, basePath string) string {
	// 		// 自定义命名逻辑
	// 		return "custom_" + filepath.Base(filePath)
	// 	},
	// }

	// 创建合并器并执行
	merger := NewExcelMerger(sourceDir, outputPath, filter, namer)
	if err := merger.Merge(); err != nil {
		fmt.Printf("错误: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("合并完成!")
}
