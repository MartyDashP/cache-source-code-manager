Class SourceControlManager.Main Extends %Studio.SourceControl.Base
{

Parameter SourceControlManagerProjects = "^SourceControlManagerProjects";

XData Menu
{
<MenuBase>
</MenuBase>
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
	$$$TOE(sc,$system.OBJ.ExportUDL(InternalName, fileName,"-d /diffexport"))
	
	if $$$ISOK(sc) {
		w !,"Exported '",InternalName,"' to file '",fileName,"'"
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

}

