        ��  ��                  �  0   ��
 R O D L F I L E                     <?xml version="1.0" encoding="utf-8"?>
<Library Name="UKLibrary" UID="{D602FDCE-8833-4895-8027-727146F6C860}" Version="3.0">
<Services>
<Service Name="LogonService" UID="{7A07FF12-397F-495F-9C0A-C70E8EA6ACAD}">
<Interfaces>
<Interface Name="Default" UID="{0C18D93C-6FF5-49BC-B4D3-E192A2581082}">
<Documentation><![CDATA[Service LogoService. This service has been automatically generated using the RODL template you can find in the Templates directory.]]></Documentation>
<Operations>
<Operation Name="_ClientConn" UID="{3FE67960-7615-4DB5-982D-DD79E229F62F}">
<Parameters>
<Parameter Name="Result" DataType="Boolean" Flag="Result">
</Parameter>
<Parameter Name="ClientInfo" DataType="Xml" Flag="In" >
</Parameter>
<Parameter Name="ServerInfo" DataType="Xml" Flag="Out" >
</Parameter>
</Parameters>
</Operation>
</Operations>
</Interface>
</Interfaces>
</Service>
<Service Name="AppService" UID="{F070A15C-A1F4-4809-A0DA-F3F579C6EE12}">
<Interfaces>
<Interface Name="Default" UID="{3EE08AE2-36C4-47A9-9E58-54BA2DD480CE}">
<Operations>
<Operation Name="GetSessionID" UID="{43D71E4C-E590-437F-822A-58EAA97D2D87}">
<Parameters>
<Parameter Name="Result" DataType="WideString" Flag="Result">
</Parameter>
<Parameter Name="NewParam" DataType="WideString" Flag="In" >
</Parameter>
</Parameters>
</Operation>
</Operations>
</Interface>
</Interfaces>
</Service>
</Services>
<Structs>
</Structs>
<Enums>
</Enums>
<Arrays>
</Arrays>
</Library>
