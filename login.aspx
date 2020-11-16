<%@ Page Language="C#" Debug="false" AutoEventWireup="True" EnableViewState="True" CodeFile="login.aspx.cs" Inherits="login" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Studio Layout Companion</title>
    <link href="/Styles/SiteDefaults.css" rel="stylesheet" type="text/css" /> 
    <script>
        function CLROnFocus(oRef) {
            var oMPD = document.getElementById("cntPwd");
            if (oRef.id == 'txtLgn' && oRef.value.trim() == 'Email or Username') {
                oRef.value = '';
                oRef.className = 'inputTxt280A';
            } else if (oRef.id == 'txtPwd' && oRef.value.trim() == '') {
                oRef.value = '';
                oRef.className = 'inputTxt280A';
                oMPD.style.visibility = "hidden";
            } else {
                oRef.className = 'inputTxt280A';
            }

        }

        function SetDefVal(oRef) {
            var oMPD = document.getElementById("cntPwd");
            if (oRef.id == 'txtLgn' && oRef.value.trim() == '') {
                oRef.value = 'Email or Username';
                oRef.className = 'inputTxt280';
            } else if (oRef.id == 'txtPwd' && oRef.value.trim() == '') {
                oRef.value = '';
                oRef.className = 'inputTxt280';
                oMPD.style.visibility = "visible";
            }
        }

        function FocusMe(oRef) {
            oRef.focus();
        }

        function ResetMe() {
            //ResetForm Login Content
            var oRef = document.getElementById("txtLgn");
            oRef.value = "";
            SetDefVal(oRef);
            oRef = document.getElementById("txtPwd");
            oRef.value = "";
            SetDefVal(oRef);
            oRef = document.getElementById("lblMsg");
            oRef.innerText = "";
            
            return false;
        }
        
    </script>
</head>
<body runat="server">
    <form id="form1" runat="server">
        <div id="logobg">
            <img src="/Images/logo/basegears.png"/>
        </div>
        <div id="grad1">
            <div id="contentLP">
                <div id="cntPwd"><asp:Label CssClass="lblTxt280" ID="lblPwd" runat="server" Text="Password"></asp:Label></div>
                <table class="LoginTable">
                    <tr>
                        <td align="center" width="45">&nbsp;</td>
                        <th colspan="3">Studio Layout Companion Login<br /><br /></th>
                    </tr>
                    <tr>
                        <td align="center" width="45">
                            <asp:RequiredFieldValidator ID="rfvLgn"  runat="server" ControlToValidate ="txtLgn" ErrorMessage='<img src="./Images/icons/Error1.png" />' InitialValue="Email or Username"></asp:RequiredFieldValidator><br /><br />
                        </td>
                        <td align="center" colspan="3">
                            <asp:Textbox CssClass="inputTxt280" ID="txtLgn" runat="server" Text="Email or Username" onFocus="CLROnFocus(this)" onBlur="SetDefVal(this)" /><br /><br />
                        </td>
                    </tr>
                    <tr>
                        <td align="center" width="45">
                            <asp:RequiredFieldValidator ID="rfvPwd"  runat="server" ControlToValidate ="txtPwd" ErrorMessage='<img src="./Images/icons/Error1.png" />' InitialValue=""></asp:RequiredFieldValidator><br />
                        </td>
                        <td align="center" colspan="3"><asp:Textbox CssClass="inputTxt280" ID="txtPwd" TextMode="Password" Text="" runat="server" onFocus="CLROnFocus(this)" OnBlur="SetDefVal(this)"/><br /></td>
                    </tr>
                    <tr>
                        <td align="center" width="45">&nbsp;</td>
                        <td align="left" valign="middle" colspan="3"><br />
                            <asp:Label id="lblMsg" CssClass="errMsg" runat="server" Text=""></asp:Label>
                            <br />
                            <br />
                        </td>
                    </tr>
                    <tr>
                        <td align="center" width="45">&nbsp;</td>
                        <td colspan="3">
                            <table width="100%" border="0">
                                <tr>
                                    <td align="left"><asp:Button CssClass="inputBtnRed" ID="btnReset" OnClick="btnReset_Click" OnClientClick="return ResetMe();" runat="server" text="Reset"/></td>
                                    <td align="right"><asp:Button CssClass="inputBtn" ID="btnLogin" OnClick="btnLogin_Click" text="Login" runat="server" onLoad="FocusMe"/></td>
                                </tr>
                            </table>
                       </td>
                    </tr>
                    <tr>
                        <td align="center" width="45">&nbsp;</td>
                        <td colspan="3"><p id="pLoginTxt"><i><b>Don't have an account? <asp:HyperLink id="hypLnk1" runat="server" NavigateUrl="./createlogin.aspx">Create One</asp:HyperLink></b></i></p></td>
                    </tr>
                </table>
            </div>
        </div>
    </form>
</body>
</html>
