<%@ Page Language="C#" Debug="true" AutoEventWireup="true" EnableViewState="True" CodeFile="createlogin.aspx.cs" Inherits="createlogin" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Studio Layout Companion</title>
    <link href="/Styles/SiteDefaults.css" rel="stylesheet" type="text/css" /> 

    <script>

        //Script For Password Strength Alone
        function getPWDStrength(pPWD) {
            var iSout = 1; //Beginning Score is 1 (hey you took the effort to at least enter a password)

            //Set Password Score based on some general expression tests
            if (/[a-z]/.test(pPWD)) iSout++;  //+1 point for having an actual character (the quick brown fox jumps over the lazy dog...) typing is fun
            if (/[A-Z]/.test(pPWD)) iSout++;  //+1 point for having an actual UPPERCASE Character (Yep it's a keyboard)
            if (/[0-9]/.test(pPWD)) iSout++;  //+1 point for having an actual NUMBER (Way to go Buddy!)
            if (/[!@#$%^&*~]/.test(pPWD)) iSout++; //+1 point for having an actual Symbol (Bravo!)
            if (pPWD.length >= 10) iSout++;  //+1 point If you password is over at least 10 characters
            if (pPWD.length >= 15) iSout++;  //+1 point If you password is over at least 15 characters
            if (/password/i.test(pPWD)) iSout--; //-1 point for using the word password (really?!?)
            if (pPWD.length >= 4 && pPWD.length <= 5) iSout = 2;  //Set score to 2 for any password that is only 4-5 characters (couldn't think of anything better?)
            if (pPWD.length <= 3) iSout = 1;  //Set score to 1 for any password that is less than 4 characters (Oh... Your getting hacked)

            //If interger Score out is great than 6 make it 6 (6= maximum)
            iSout = (iSout > 6) ? 6 : iSout;

            return iSout;
        }

        function CheckPwdStrength(oRef) {
            var cv = document.getElementById("pscan");
            var smsg = document.getElementById("pMsg");
            if (cv.getContext) {
                //Default Values
                var ctx = cv.getContext("2d");
                var cos = 4;
                var cw = 25;
                var ch = 8;
                var msg = "";
                var fColor = "";

                //Rated Security Score
                var rs = getPWDStrength(oRef.value);

                
                //Clear Canvas
                ctx.clearRect(0, 0, cv.width, cv.height);
                smsg.innerText = " ";

                if (oRef.value.trim() == "")
                    return;
                

                for (var i = 0; i < rs; i++) {
                    //Based on Score set colors and message
                    //Originally i used rs, but changed it to i+1 so i can get the progression of colors
                    switch (i + 1) {
                        case 1:
                            ctx.strokeStyle = "#440000";
                            ctx.fillStyle = "#FF4444";
                            fColor = "#660000";
                            msg = "Seriously?!?";
                            break;
                        case 2:
                            ctx.strokeStyle = "#442200";
                            ctx.fillStyle = "#EEAA44";
                            fColor = ctx.fillStyle;
                            msg = "You sure about that?";
                            break;
                        case 3:
                            ctx.strokeStyle = "#444400";
                            ctx.fillStyle = "#DDDD44";
                            fColor = ctx.fillStyle;
                            msg = "Meh... It's Ok";
                            break;
                        case 4:
                            ctx.strokeStyle = "#226622";
                            ctx.fillStyle = "#44AA44";
                            fColor = "#44DD44";
                            msg = "Almost Their...";
                            break;
                        case 5:
                            ctx.strokeStyle = "#337733";
                            ctx.fillStyle = "#55CC55";
                            fColor = ctx.fillStyle;
                            msg = "A little better...";
                            break;
                        case 6:
                            ctx.strokeStyle = "#447744";
                            ctx.fillStyle = "#99FF99";
                            fColor = ctx.fillStyle;
                            msg = "There you Go!";
                            break;
                        default:
                            ctx.fillStyle = "#000000";
                            msg = "";
                    }
                    //Color of Box and Message
                    smsg.style.color = fColor;
                    //smsg.style.fontSize = "10pt";
                    smsg.style.fontWeight = "bold";
                    smsg.innerText= msg;

                    //Draw Outline of Shape
                    ctx.strokeRect(((cw + cos) * i), 0, cw, ch);

                    //Fill Rectangle
                    ctx.fillRect(((cw + cos) * i) + 1, 1, cw - 1, ch - 2);
                }
            }
            return;
        }

        function FocusMe(oRef) {
            oRef.focus();
        }

        function ResetMe() {
            //ResetForm Login Content
            //var oRef = document.getElementById("txtLgn");
            //oRef.value = "";
            //SetDefVal(oRef);
            //oRef = document.getElementById("txtPwd");
            //oRef.value = "";
            //SetDefVal(oRef);
            //oRef = document.getElementById("lblMsg");
            //oRef.innerText = "";
            window.alert('Got Here');
            return false;
        }

        function MatchCheck(sBaseName) {
            var oRef1 = document.getElementById("txt" + sBaseName + "1");
            var oRef2 = document.getElementById("txt" + sBaseName + "2");
            var oImgRef1 = document.getElementById("icn" + sBaseName + "1");
            var oImgRef2 = document.getElementById("icn" + sBaseName + "2");

            var ImgUrl_Match = "./Images/icons/match1.png";
            var ImgUrl_Wrn = "./Images/icons/warn1.png";

            if (oRef2.value == "") {
                oImgRef2.src = "";
                oImgRef2.style = "visibility: hidden;";
            }
            else if (oRef1.value == oRef2.value && oRef1.value.trim() != "" && oRef2.value.trim() != "") {
                //oImgRef1.src = ImgUrl_Match;
                oImgRef2.src = ImgUrl_Match;
                //oImgRef1.style = "visibility: visible;";
                oImgRef2.style = "visibility: visible;";
            } else {
                oImgRef1.src = "";
                oImgRef2.src = ImgUrl_Wrn;
                oImgRef1.style = "visibility: hidden;";
                oImgRef2.style = "visibility: visible;";
            }

        }
    </script>

</head>
<body runat="server">
    <form id="form1" runat="server">
        <div id="logobg">
            <img src="/Images/logo/basegears.png" />
        </div>
        <div id="logoTitleBar">
            <p id="TitleBarTxt">Create An Account</p>
        </div>
        <%--<div id="grad1">--%>
            <div id="contentCA">
                <table class="CATable">
                    <tr>
                        <td align="center" colspan="5" rowspan="8" style="width: 225px;">&nbsp;</td>
                        <td align="left" colspan="2">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblUserName" runat="server" Text="User Name:"></asp:Label></u>
                        </td>
                        <td align="center" colspan="8">&nbsp;</td><!--8-->
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:Image runat="server" ID="icnUserName" ImageUrl="./Images/icons/error1.png" style="visibility:hidden"/>
                            <%--<asp:RequiredFieldValidator ID="rfvUSER"  runat="server" ControlToValidate="txtUserName" ErrorMessage='<img src="./Images/icons/match1.png" />' InitialValue=""></asp:RequiredFieldValidator>--%>
                            <br />
                        </td>
                        <td align="left">
                            <asp:TextBox CssClass="inputTxt200A" ID="txtUserName" runat="server" Text="" MaxLength="20" TabIndex="1" CausesValidation="True"></asp:TextBox>
                            <asp:CustomValidator runat="server" ControlToValidate="txtUserName" ID="cvUserName" EnableClientScript="false" OnServerValidate="cvUserName_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td><!--8-->
                        <td align="left" colspan="8">&nbsp;<asp:Label id="lblUNMsg" CssClass="errMsg" runat="server" Text=""></asp:Label></td><!--8-->
                    </tr>
                    <tr>
                        <td align="left" colspan="10" height="5">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="left" colspan="2" width="90">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblFName" runat="server" Text="First Name:"></asp:Label></u>
                        </td>
                        <td align="center" width="40">&nbsp;</td>
                        <td align="left" colspan="6">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblLName" runat="server" Text="Last Name:"></asp:Label></u>
                        </td>
                        <td align="center" width="40">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:Image runat="server" ID="icnFName" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtFName" ID="cvFName" EnableClientScript="false" OnServerValidate="cvFName_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="2"><asp:TextBox CssClass="inputTxt200A" ID="txtFName" Text="" runat="server" MaxLength="30" TabIndex="2" /><br /></td>
                        <td align="center" width="40">
                            <asp:Image runat="server" ID="icnLName" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtLName" ID="cvLName" EnableClientScript="false" OnServerValidate="cvLName_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="5"><asp:TextBox CssClass="inputTxt200A" ID="txtLName" text="" runat="server" MaxLength="30" TabIndex="3" /><br /></td>
                        <td align="center" width="40">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="left" colspan="10" height="5">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="left" colspan="2">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblPhone" runat="server" Text="Phone Number:"></asp:Label></u>
                        </td>
                        <td align="center" colspan="8">&nbsp;</td><!--8-->
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:CustomValidator runat="server" ControlToValidate="txtPhone" ID="cvPhone" EnableClientScript="false" OnServerValidate="cvPhone_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                            <asp:Image runat="server" ID="icnPhone" ImageUrl="./Images/icons/Error1.png" />
                            <br />
                        </td>
                        <td align="left"><asp:TextBox CssClass="inputTxt200A" ID="txtPhone" Text="" TextMode="Phone" MaxLength="10" runat="server" ToolTip="10  Digit Phone Number" ViewStateMode="Inherit" CausesValidation="False" TabIndex="4" /><br /></td>
                        <td align="center" colspan="8">&nbsp;</td><!--8-->
                    </tr>
                    <tr>
                        <td align="right" colspan="18" height="5">&nbsp;
                            <asp:Label id="lblMsg" CssClass="errMsg" runat="server" Text=""></asp:Label>
                        </td>
                    </tr>
                    <tr>
                        <td align="left" colspan="7">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblSQ" runat="server" Text="Security Questions:"></asp:Label></u>
                        </td>
                        <td align="center" width="40">&nbsp;</td>
                        <td align="left" colspan="7">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblEMail" runat="server" Text="Email Address:"></asp:Label></u>
                        </td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSQ1"  runat="server" ControlToValidate="ddlSQ1" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:DropDownList CssClass="inputDDLSQ" ID="ddlSQ1" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlSQ1_SelectedIndexChanged" TabIndex="5"></asp:DropDownList> <br /></td>
                        <td align="center" width="40">
                            <asp:Image runat="server" ID="icnEML1" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtEML1" ID="cvEML1" EnableClientScript="false" OnServerValidate="cvEML1_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="6"><asp:TextBox CssClass="inputTxt280A" ID="txtEML1" Text="" runat="server" MaxLength="60" TabIndex="11" onKeyUp="MatchCheck('EML');" /><br /></td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSA1"  runat="server" ControlToValidate="txtSA1" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue="" TabIndex="0"></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:TextBox CssClass="inputTxt200A" ID="txtSA1" Text="" runat="server" MaxLength="50" TabIndex="6" /><br /></td>
                        <td align="center" width="40">
                            <asp:Image runat="server" ID="icnEML2" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtEML2" ID="cvEML2" EnableClientScript="false" OnServerValidate="cvEML2_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="6"><asp:TextBox CssClass="inputTxt280A" ID="txtEML2" Text="" runat="server" MaxLength="60" ToolTip="Confirm Email" TabIndex="12" onKeyUp="MatchCheck('EML');"  /><br /></td>
                    </tr>
                    <tr>
                        <td align="left" colspan="15" height="5">&nbsp;</td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSQ2"  runat="server" ControlToValidate="ddlSQ2" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:DropDownList CssClass="inputDDLSQ" ID="ddlSQ2" runat="server" AutoPostBack="true" OnSelectedIndexChanged="ddlSQ2_SelectedIndexChanged" TabIndex="7"></asp:DropDownList> <br /></td>
                        <td align="left" colspan="2">
                            <u><asp:Label CssClass="lblFldTxt" ID="lblPwd" runat="server" Text="Password:"></asp:Label></u><br />
                            <asp:Label ID="lblCaseSen" runat="server" Text="(Case Sensative)" ForeColor="#FFEE55" Font-Bold="True" Font-Italic="True" Font-Size="Smaller"></asp:Label>
                        </td>
                        <td align="center" width="40">
                            <%--<asp:RequiredFieldValidator ID="rfvPWD1"  runat="server" ControlToValidate="txtPWD1" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator>--%>
                            <asp:Image runat="server" ID="icnPWD1" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtPWD1" ID="cvPWD1" EnableClientScript="false" OnServerValidate="cvPWD1_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="4"><asp:TextBox CssClass="inputTxt200A" ID="txtPWD1" Text="" TextMode="Password" runat="server" onKeyUp="CheckPwdStrength(this);" onKeyPress="MatchCheck('PWD');" MaxLength="40" TabIndex="13"/> <br /></td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSA2"  runat="server" ControlToValidate ="txtSA2" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:TextBox CssClass="inputTxt200A" ID="txtSA2" Text="" runat="server" MaxLength="50" TabIndex="8" /><br /></td>
                        <td align="left" valign="bottom" colspan="2">&nbsp;</td>
                        <td align="center" width="40">
                            <%--<asp:RequiredFieldValidator ID="rfvPWD2"  runat="server" ControlToValidate ="txtPWD2" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator>--%>
                            <asp:Image runat="server" ID="icnPWD2" ImageUrl="./Images/icons/Error1.png" />
                            <asp:CustomValidator runat="server" ControlToValidate="txtPWD2" ID="cvPWD2" EnableClientScript="false" OnServerValidate="cvPWD2_ServerValidate" ValidateRequestMode="Inherit" ValidateEmptyText="true"></asp:CustomValidator>
                        </td>
                        <td align="left" colspan="4"><asp:TextBox CssClass="inputTxt200A" ID="txtPWD2" Text="" TextMode="Password" runat="server" MaxLength="40" ToolTip="Confirm Password" TabIndex="14" onKeyUp="MatchCheck('PWD');" /><br /></td>
                    </tr>
                    <tr>
                        <td align="center" colspan="8" height="5">&nbsp;</td>
                        <td align="right" colspan="3" height="5">&nbsp;</td>
                        <td align="center" colspan="4" height="5"><canvas id="pscan" width="180" height="12" title="Password Strength"></canvas></td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSQ3"  runat="server" ControlToValidate="ddlSQ3" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:DropDownList CssClass="inputDDLSQ" ID="ddlSQ3" runat="server"  AutoPostBack="true" OnSelectedIndexChanged="ddlSQ3_SelectedIndexChanged" TabIndex="9"></asp:DropDownList> <br /></td>
                        <td align="center" valign="top" colspan="3">&nbsp;</td>
                        <td align="center" colspan="7"><p id="pMsg" style="font-size: small;" title="Password Strength"></p></td>
                    </tr>
                    <tr>
                        <td align="center" width="40">
                            <asp:RequiredFieldValidator ID="rfvSA3"  runat="server" ControlToValidate ="txtSA3" ErrorMessage='<img src="./Images/icons/Error1.png"/>' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="left" colspan="7"><asp:TextBox CssClass="inputTxt200A" ID="txtSA3" Text="" runat="server" MaxLength="50" TabIndex="10" /><br /></td>
                        <td align="center" colspan="7">
                            <table width="100%" border="0">
                                <tr>
                                     <%--OnClientClick ="return ResetMe();"--%> 
                                    <td align="left"><asp:Button CssClass="inputBtnRed" ID="btnCancel" OnClick="btnCancel_Click" OnClientClick="return true;" runat="server" text="Cancel" TabIndex="15" /></td>
                                    <td align="right"><asp:Button CssClass="inputBtn" ID="btnSave" OnClick="btnSave_Click" text="Save" runat="server" onLoad="FocusMe" TabIndex="16" ValidationGroup="UserNM"/></td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </div>
        <%--</div>--%>
    </form>
</body>
</html>
