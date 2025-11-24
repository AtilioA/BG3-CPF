export const HELP_URL = "https://www.nexusmods.com/baldursgate3/mods/9162";
export const GITHUB_URL = "https://github.com/AtilioA/BG3-CPF/";

export const META_LSX_TEMPLATE = `<?xml version="1.0" encoding="UTF-8"?>
<save>
    <version major="4" minor="8" revision="0" build="500"/>
    <region id="Config">
        <node id="root">
            <children>
                <node id="Conflicts"/>
                <node id="Dependencies">
                    <children>
                        <node id="ModuleShortDesc">
                            <attribute id="Folder" type="LSString" value="CPF"/>
                            <attribute id="MD5" type="LSString" value=""/>
                            <attribute id="Name" type="LSString" value="Character Preset Framework"/>
                            <attribute id="PublishHandle" type="uint64" value="0"/>
                            <attribute id="UUID" type="guid" value="4fa17abe-993c-4e7e-ab2a-e7370b166ac9"/>
                            <attribute id="Version64" type="int64" value="36028797018963968"/>
                        </node>{{ADDITIONAL_DEPENDENCIES}}
                    </children>
                </node>
                <node id="ModuleInfo">
                    <attribute id="Author" type="LSString" value="{{AUTHOR}}"/>
                    <attribute id="CharacterCreationLevelName" type="FixedString" value=""/>
                    <attribute id="Description" type="LSString" value="{{DESCRIPTION}}"/>
                    <attribute id="FileSize" type="uint64" value="881247"/>
                    <attribute id="Folder" type="LSString" value="{{FOLDER}}"/>
                    <attribute id="LobbyLevelName" type="FixedString" value=""/>
                    <attribute id="MD5" type="LSString" value="c0a8f3412870277331306e0719fc6f77"/>
                    <attribute id="MenuLevelName" type="FixedString" value=""/>
                    <attribute id="Name" type="LSString" value="{{NAME}}"/>
                    <attribute id="NumPlayers" type="uint8" value="4"/>
                    <attribute id="PhotoBooth" type="FixedString" value=""/>
                    <attribute id="StartupLevelName" type="FixedString" value=""/>
                    <attribute id="UUID" type="FixedString" value="{{UUID}}"/>
                    <attribute id="Version64" type="int64" value="36028797018963978"/>
                    <children>
                        <node id="PublishVersion">
                            <attribute id="Version64" type="int64" value="36028797018963978"/>
                        </node>
                        <node id="Scripts" />
                    </children>
                </node>
            </children>
        </node>
    </region>
</save>`;
