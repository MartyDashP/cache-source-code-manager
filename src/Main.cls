Class SourceCodeManager.Main Extends %Studio.SourceControl.Base
{

Parameter SourceCodeManager = "^SourceCodeManager";

Parameter projectsNodeName = "projects";

XData Menu
{
<MenuBase>
</MenuBase>
}

Parameter Flags As STRING = 0000;

Method UserAction(Type As %Integer, Name As %String, InternalName As %String, SelectedText As %String, ByRef Action As %String, ByRef Target As %String, ByRef Msg As %String, ByRef Reload As %Boolean) As %Status
{
	if ((Type = 1) && (Name = 2))
	{
		ret ..RemoveSourceFile(InternalName)
	}
	
	ret $$$OK
}

ClassMethod GetRootPackageName(InternalName As %String) As %String
{
	ret $lg($lfs(InternalName,"."),1,"")
}

ClassMethod GetDirProject(projectName As %String) As %String
{
	if (@..#SourceCodeManager("projects", projectName) = "")
	{
		s dir = @..#SourceCodeManager("projects", "*")
	}
	else
	{
		s dir = @..#SourceCodeManager("projects", projectName)
	}

	ret:(dir = "") ""

	if ($lf($lb("/","\"),$e(dir,*)) = 0)
	{
		s dir = dir _ "\"
	}

	ret dir
}

ClassMethod ImportSourceFiles(projectName As %String, doCompilng As %Boolean = 1) As %Status
{
	s rootDir = ..GetDirProject(projectName)
	
	if (rootDir = "")
	{
		w "Directory for project '"_projectName_"' is undefined"
		ret $$$OK
	}

	if doCompilng
	{
		s params = "c"
	}

	s sc = $system.OBJ.LoadDir(rootDir, params, .errLogs, 1)

	if (errLogs '= "")
	{
		w "Errors: "_errLogs
	}

	ret sc
}

ClassMethod UpdateSource(projectName As %String) As %Status
{
	s rootDir = ..GetDirProject(projectName)
	
	if (rootDir = "")
	{
		w "Project '"_projectName_"' is undefined"
		ret $$$OK
	}
	
	d $system.OBJ.DeletePackage(projectName)
	
	ret ..ImportSourceFiles(projectName)
}

Method ExternalName(InternalName As %String) As %String
{
	s rootPackageName = ..GetRootPackageName(InternalName)
	s rootDir = ..GetDirProject(rootPackageName)
	ret:(rootDir = "") ""

	s type = $zcvt($li($lfs(InternalName,"."), -1), "l")
	s fileName = $lts($li($lfs(InternalName,"."), 2, *-1),"\")_"."_type
	s anyTypeSubPath =  $g(@..#SourceCodeManager("projects", rootPackageName,"*"),"\")
	s typedSubPath = $g(@..#SourceCodeManager("projects", rootPackageName, type), anyTypeSubPath)

	if ($lf($lb("/","\"),$e(typedSubPath,*)) = 0)
	{
		s typedSubPath = typedSubPath _ "\"
	}

	s resultPath = rootDir_typedSubPath_fileName
	
	if $$$isWINDOWS
	{
		ret $replace($tr(resultPath, "\", "/"), "//", "/")
	}

	ret $replace($tr(resultPath, "/", "\"), "\\", "\")
}

Method IsSkipSourceCodeManagerPackage(InternalName As %String) As %Boolean
{
	s isSkip =  $g(@..#SourceCodeManager("config", "skipSourceCodeManagerPackage"), 1)

	ret:(isSkip = 0) 0
	ret ($lg($lfs(InternalName,"."),1) = $lg($lfs(..%ClassName(1),"."),1,""))
}

Method ExportSourceFile(InternalName As %String) As %Status
{
	if (($data(@..#SourceCodeManager) = 0) || ..IsSkipSourceCodeManagerPackage(InternalName))
	{
		ret $$$OK
	}

	s fileName = ..ExternalName(InternalName)
	
	ret:(fileName = "") $$$OK
	
	d ##class(%File).CreateDirectoryChain(##class(%File).GetDirectory(fileName))	
	s sc = $system.OBJ.ExportUDL(InternalName, fileName,"-d /diffexport")
	
	if $$$ISOK(sc) 
	{
		w !,"Exported '",InternalName,"' to file '",fileName,"'"
	}
	else
	{
		w !,InternalName," can't export"
	}
	
	ret sc
}

Method OnAfterSave(InternalName As %String, Object As %RegisteredObject = {$$$NULLOREF}) As %Status
{
	ret ..ExportSourceFile(InternalName)
}

Method OnAfterCompile(InternalName As %String) As %Status
{
	ret ..ExportSourceFile(InternalName)
}

Method RemoveSourceFile(InternalName As %String) As %Status
{
	s fileName = ..ExternalName(InternalName)
	
	ret:(fileName = "") $$$OK
	
	s isSuccess = ##class(%File).Delete(fileName)
	
	if isSuccess
	{
		w !,"Deleted: ",fileName
	}
	else
	{
		w !,"File '",fileName,"' not deleted"
	}
	
	Quit $$$OK
}

}

