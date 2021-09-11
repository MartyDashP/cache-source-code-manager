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

Method ExternalName(InternalName As %String) As %String
{
	s rootPackageName = $lg($lfs(InternalName,"."),1,"")
	s type = $zcvt($li($lfs(InternalName,"."), -1), "l")
	s fileName = $lts($li($lfs(InternalName,"."), 2, *-1),"\")_"."_type

	if (@..#SourceCodeManager("projects", rootPackageName) = "")
	{
		s rootDir = @..#SourceCodeManager("projects", "*")
	}
	else
	{
		s rootDir = @..#SourceCodeManager("projects", rootPackageName)
	}

	ret:(rootDir = "") ""

	w $$$isWINDOWS
	

	if ($lf($lb("/","\"),$e(rootDir,*)) = 0)
	{
		s rootDir = rootDir _ "\"
	}

	s anyTypeSubPath =  $g(@..#SourceCodeManager("projects", rootPackageName,"*"),"\")
	s typedSubPath = $g(@..#SourceCodeManager("projects", rootPackageName, type), anyTypeSubPath)

	if ($lf($lb("/","\"),$e(typedSubPath,*)) = 0)
	{
		s typedSubPath = typedSubPath _ "\"
	}

	s resultPath = rootDir_typedSubPath_fileName
	
	if $$$isWINDOWS
	{
		ret $tr(resultPath, "\","/")
	}

	ret $tr(resultPath, "/","\")
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

