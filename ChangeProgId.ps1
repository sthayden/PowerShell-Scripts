
$progID = Read-Host -Prompt 'type your Program Id and hit Enter'

$webConfigPath = "C:\B-cycle\B-cycle.exe.Config"      #Path to the config file. Make sure file is not read-only 

$RptKeyFound=0;

$xml = [xml](get-content $webConfigPath);              # Create the XML Object and open the web.config file 
$root = $xml.get_DocumentElement();                     # Get the root element of the file

foreach( $item in $root.appSettings.add)                  # loop through the child items in appsettings 
{ 
  if($item.key –eq “ProgramId”)                       # If the desired element already exists 
    { 
      $item.value = “$progID”;                          # Update the value attribute 
      $RptKeyFound=1;                                             # Set the found flag 
    } 
}

if($RptKeyFound -eq 0)                                                   # If the desired element does not exist 
{ 
    $newEl=$xml.CreateElement("add");                               # Create a new Element 
    $nameAtt1=$xml.CreateAttribute("key");                         # Create a new attribute “key” 
    $nameAtt1.psbase.value="ProgramId";                    # Set the value of “key” attribute 
    $newEl.SetAttributeNode($nameAtt1);                              # Attach the “key” attribute 
    $nameAtt2=$xml.CreateAttribute("value");                       # Create “value” attribute  
    $nameAtt2.psbase.value="$progID";                       # Set the value of “value” attribute 
    $newEl.SetAttributeNode($nameAtt2);                               # Attach the “value” attribute 
    $xml.configuration["appSettings"].AppendChild($newEl);    # Add the newly created element to the right position

}

$xml.Save($webConfigPath)                                                # Save the web.config file