Class SourceControlManager.Main Extends %Studio.SourceControl.Base
{

Parameter SourceControlManagerProjects = "^SourceControlManagerProjects";

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
	
	s rootDir = @..#SourceControlManagerProjects(rootPackageName)
		
	s subPath = $case(type,
		"cls": "cls\",
		"inc": "inc\",
		:"unknowtype\")
	
	if ((rootDir = "") || $f(InternalName,".Generated."))
	{
		ret ""
	}
	
	s resultPath = $tr(rootDir_subPath_fileName,"\","/")
	ret resultPath
}

Method ExportSourceFile(InternalName As %String) As %Status
{
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

