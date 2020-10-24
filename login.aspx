<%@ Page Language="C#" AutoEventWireup="true" CodeFile="login.aspx.cs" Inherits="login" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <link href="/Styles/SiteDefaults.css" rel="stylesheet" type="text/css" /> 
<%--    <link rel="/js/stylesheet" href="jquery-ui.min.css">
    <script src="/js/external/jquery/jquery.js"></script>
    <script src="/js/jquery-ui.min.js"></script>--%>
    <script>
        function CLROnFocus(oRef) {
              
            if (oRef.id == 'txtLgn' && oRef.value.trim() == 'Email or Username') {
                oRef.value = '';
                oRef.className = 'inputTxt200A';
            }
            if (oRef.id == 'txtPwd' && oRef.value.trim() == 'Password') {
                oRef.value = '';
                oRef.className = 'inputTxt200A';
            }

        }

        function SetDefVal(oRef) {
            if (oRef.id == 'txtLgn' && oRef.value.trim() == '') {
                oRef.value = 'Email or Username';
                oRef.className = 'inputTxt200';
                
            }
            if (oRef.id == 'txtPwd' && oRef.value.trim() == '') {
                oRef.value = 'Password';
                oRef.className = 'inputTxt200';
            }
        }

        function FocusMe(oRef) {
            oRef.focus();
        }
        
    </script>
</head>
<body>
    <form id="form1" runat="server">
        <div id="logobg">
            <img src="/Images/logo/basegears.png" border="0" />
        </div>
        <div id="grad1">
            <div id="content">
                <table>
                    <tr>
                        <th colspan="2">Studio Layout Companion Login<br /><br /></th>
                    </tr>
                    <tr>
                        <td align="center" colspan="2">
                            <asp:TextBox class="inputTxt200" ID="txtLgn" runat="server" Value="Email or Username" onFocus="CLROnFocus(this)" onBlur="SetDefVal(this)" /><br />
                            <asp:Label id="lblMsg" class="errMsg" runat="server" Text="" EnableViewState="false"></asp:Label>
                            <%--<asp:RequiredFieldValidator ID="rfvLgn"  runat="server" ControlToValidate ="txtLgn" ErrorMessage="Please enter your Login"  
                            InitialValue="Email or Username"></asp:RequiredFieldValidator>--%>
                            <br />
                            
                        </td>
                    </tr>
                    <tr>
                        <td align="center" colspan="2"><asp:TextBox class="inputTxt200" ID="txtPwd" TextMode="Password" Value="Password" runat="server" onFocus="CLROnFocus(this)" onBlur="SetDefVal(this)"/><br />
                            <%-- <asp:RequiredFieldValidator ID="rfvPwd"  runat="server" ControlToValidate ="txtPwd" ErrorMessage="Please enter your Password"  
                            InitialValue="Password"></asp:RequiredFieldValidator>--%>
                            <br /></td>
                    </tr>
                    <tr>
                        <td align="left">&nbsp;<asp:Button class="inputBtnRed" ID="btnReset" OnClick="btnReset_Click" runat="server" text="Reset"/></td>
                        <td align="right"> <asp:Button class="inputBtn" ID="btnLogin" OnClick="btnLogin_Click" text="Login" runat="server" onLoad="FocusMe"/>&nbsp;</td>
                    </tr>
                </table>
                <p id="pLoginTxt"><i><b>Don't have an account? <a href="/createlogin.aspx" target="_parent">Create One</a></b></i></p>
                <asp:SqlDataSource ID="SQLSrc1" Runat="server" 
                    SelectCommand="Select * V_USERS"
                    ConnectionString="<%$ ConnectionStrings:DBConn %>" />
            </div>
        </div>
    </form>
</body>
</html>
