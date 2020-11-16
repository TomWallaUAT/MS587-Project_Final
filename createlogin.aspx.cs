using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.SqlClient;
using System.Data;
using System.Configuration;
using System.Text.RegularExpressions;

public enum UserInfoType
{
    Email, UserName
}

public partial class createlogin : System.Web.UI.Page 
{
    string connStr = ConfigurationManager.ConnectionStrings["DBConn"].ConnectionString;
    int iQID1 = 0;
    int iQID2 = 0;
    int iQID3 = 0;
    int iDX1 = 0;
    int iDX2 = 0;
    int iDX3 = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!@Page.IsPostBack)
        {
            ResetEUMsgs();
            //System.Diagnostics.Debug.WriteLine("Page_Load");
            PopulateDDL(ddlSQ1, 0);
            PopulateDDL(ddlSQ2, 0);
            PopulateDDL(ddlSQ3, 0);
        }
    }

    protected void PopulateDDL(DropDownList oRef, int iIGQ1 = 0, int iIGQ2 = 0)
    {
        DataTable dt = new DataTable();
        SqlConnection con = new SqlConnection(connStr);
        try
        {
            con.Open();
            SqlCommand com = new SqlCommand("csp_GetSecQuestions", con)
            {
                CommandType = CommandType.StoredProcedure,
            };
            com.Parameters.AddWithValue("@IGNORE_QID1", iIGQ1);
            com.Parameters.AddWithValue("@IGNORE_QID2", iIGQ2);
            using (SqlDataReader dr = com.ExecuteReader())
            {
                if (dr.HasRows)
                {
                    oRef.Items.Clear();
                    while (dr.Read())
                    {
                        oRef.Items.Add(new ListItem(dr["SEC_QUEST_TXT"].ToString(), dr["SEC_QUEST_ID"].ToString()));
                        //System.Diagnostics.Debug.WriteLine(dr["SEC_QUEST_TXT"].ToString());
                    }
                }
            }
            oRef.Items.Insert(0, new ListItem(string.Format("--Select Question {0}--", oRef.ID.ToString().Replace("ddlSQ", "")),""));
            oRef.DataBind();

            //Close Connection
            con.Close();
        }
        catch (Exception ex) {
            //System.Diagnostics.Debug.WriteLine("ERROR: " + ex.Message.ToString().Trim());
        }
    }

    private string SQLString(string sValue)
    {
        if (sValue is null)
        {
            sValue = "";
        }
        return "'" + sValue + "'";
    }

    protected void btnSave_Click(object sender, EventArgs e)
    {
        
        string sMsg = "";
        string sUID = "";
        int iRes = 0;

        if (Page.IsPostBack)
        {
            Page.Validate();
            if (Page.IsValid)
            {
                DataTable dt = new DataTable();
                SqlConnection con = new SqlConnection(connStr);

                //RETURN_VALUE - HOLDS THE INTEGER RETURN VALUE FROM THE PROCEDURE (0,1,2 or 3) - EACH HAVE MEANING 
                //  0 -Invalid Login, 1 - Login Successful (Verified), 2=Login Successful (Not Verified)  / 3 - Account Locked (# min(s))
                SqlParameter parRet = new SqlParameter("returnVal", SqlDbType.Int) {Direction = ParameterDirection.ReturnValue};

                /*
    @USER_ID		varchar(60),
    @USER_PWD		varchar(40),
    @USER_EMAIL		varchar(60),
    @SEC_QID_1		TINYINT,
    @SEC_QID_2		TINYINT,
    @SEC_QID_3		TINYINT,
    @SEC_QANS_1		varchar(100),
    @SEC_QANS_2		varchar(100),
    @SEC_QANS_3		varchar(100),
    @USER_FNAME		varchar(30),
    @USER_LNAME		varchar(30),
    @USER_PHONE		varchar(10),
    @USER_VRFY_PREF_CD CHAR(1) = 'N',
    @USR			varchar(60) = null
 */

                //DATA BASE CALL TO THE PROCEDURE FOR LOGIN
                SqlCommand com = new SqlCommand("csp_ADD_User") {CommandType = CommandType.StoredProcedure, Connection = con};

                com.Parameters.AddWithValue("@USER_NM", txtUserName.Text.ToString());
                com.Parameters.AddWithValue("@USER_PWD", txtPWD1.Text.ToString());

                com.Parameters.Add(parRet);

                con.Open();
                com.ExecuteNonQuery();
                
                sMsg = (string)com.Parameters["@MSG_OUT"].Value;

                //TRY TO RETRIEVE USERNAME IF NOT ASSIGN BLANK
                try
                {
                    sUID = (string)com.Parameters["@UID_OUT"].Value;
                } catch (Exception)
                {
                    sUID = "";
                }

                iRes = (int)com.Parameters["returnVal"].Value;

                
                if (iRes == 0 || iRes==3)
                {
                    //INVALID LOGIN / ACCOUNT FOUND (BUT LOCKED)
                    lblMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#BB2200");
                    System.Diagnostics.Debug.WriteLine(String.Format("Message: ({0}) - {1} - \"{2}\"", sUID, iRes, sMsg.ToString()));
                    //System.Diagnostics.Debug.WriteLine(String.Format("Message: {0} - \"{1}\"", iRes, sMsg.ToString()));
                    lblMsg.Text = sMsg.ToString();
                    
                    Session["UID"] = null;
                    Session["ULResults"] = iRes;
                    ResetCTRL();
                } else
                {
                    //VALID LOGIN
                    System.Diagnostics.Debug.WriteLine(String.Format("Message: ({0}) - {1} - \"{2}\"", sUID, iRes, sMsg.ToString()));
                    //No message needed to be displayed
                    Session["UID"] = sUID;
                    Session["ULResult"] = iRes;
                    lblMsg.Text = "";
                    ResetCTRL();
                    Response.Redirect("./MainMenu.aspx", false);
                    Context.ApplicationInstance.CompleteRequest();
                }
                con.Close();

            }
            //else
            //{
            //    lblMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#BB2200");
            //    lblMsg.Text = "Page.IsValid is False!";
            //}
        }
    }

    private void ResetEUMsgs()
    {
        lblMsg.Text = "";
        lblUNMsg.Text = "";
        icnUserName.ImageUrl = "/Images/icons/error1.png";
        lblUNMsg.Attributes["style"] = "visibility: hidden;";
        lblMsg.Attributes["style"] = "visibility: hidden;";
        icnUserName.Attributes["style"] = "visibility: hidden;";
        icnFName.Attributes["style"] = "visibility: hidden;";
        icnLName.Attributes["style"] = "visibility: hidden;";
        icnPhone.Attributes["style"] = "visibility: hidden;";
        //icnEML1.Attributes["style"] = "visibility: hidden;";
        //icnEML2.Attributes["style"] = "visibility: hidden;";
        //icnPWD1.Attributes["style"] = "visibility: hidden;";
        //icnPWD2.Attributes["style"] = "visibility: hidden;";
    }

    protected void ResetCTRL()
    {
        //RESET CONTROLS
        txtUserName.Text = "";
        txtEML1.Text = "";
        txtEML2.Text = "";
        txtPhone.Text = "";
        txtPWD1.Text = "";
        txtPWD2.Text = "";
        ddlSQ1.SelectedIndex = 0;
        ddlSQ2.SelectedIndex = 0;
        ddlSQ3.SelectedIndex = 0;
        txtSA1.Text = "";
        txtSA2.Text = "";
        txtSA3.Text = "";
    }

    protected void btnCancel_Click(object sender, EventArgs e)
    {
        ResetCTRL();
        Response.Redirect("./login.aspx", false);
        Context.ApplicationInstance.CompleteRequest();
    }

    protected void FocusMe(object sender, EventArgs e)
    {
        btnSave.Focus();
    }

    private int ReturnDDLIndex(DropDownList oRef, string sValue)
    {
        int iIDX = 0;
        int i;

        //Returns INDEX of the selected item's value
        for (i = 0; i < oRef.Items.Count; i++)
            if (oRef.Items[i].Value == sValue)
                return i;

        return iIDX;
    }

    protected void ddlSQ1_SelectedIndexChanged(object sender, EventArgs e)
    {
        //KEEP TRACK OF INDEX OF SELECTED VALUE (USED TO REASSIGN WHEN DROP DOWN CONTENT CHANGES)
        if (ddlSQ1.SelectedIndex > 0)
        {
            iQID1 = (ddlSQ1.Items[ddlSQ1.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ1.Items[ddlSQ1.SelectedIndex].Value));
            iDX1 = ReturnDDLIndex(ddlSQ1, iQID1.ToString());
        }
        if (ddlSQ2.SelectedIndex > 0)
        {
            iQID2 = (ddlSQ2.Items[ddlSQ2.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ2.Items[ddlSQ2.SelectedIndex].Value));
            iDX2 = ReturnDDLIndex(ddlSQ2, iQID2.ToString());
        }
        if (ddlSQ3.SelectedIndex > 0)
        {
            iQID3 = (ddlSQ3.Items[ddlSQ3.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ3.Items[ddlSQ3.SelectedIndex].Value));
            iDX3 = ReturnDDLIndex(ddlSQ3, iQID3.ToString());
        }

        //System.Diagnostics.Debug.WriteLine(string.Format("Values: {0}, {1}, {2}", iQID1, iQID2, iQID3));

        //Populate Drop Down List (DDL) and select the original value if available, otherwise select 0
        PopulateDDL(ddlSQ2, iQID1, iQID3);
        ddlSQ2.SelectedIndex = ReturnDDLIndex(ddlSQ2, iQID2.ToString());
        PopulateDDL(ddlSQ3, iQID1, iQID2);
        ddlSQ3.SelectedIndex = ReturnDDLIndex(ddlSQ3, iQID3.ToString());
        txtSA1.Text = "";
    }

    protected void ddlSQ2_SelectedIndexChanged(object sender, EventArgs e)
    {
        //KEEP TRACK OF INDEX OF SELECTED VALUE (USED TO REASSIGN WHEN DROP DOWN CONTENT CHANGES)
        if (ddlSQ1.SelectedIndex > 0)
        {
            iQID1 = (ddlSQ1.Items[ddlSQ1.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ1.Items[ddlSQ1.SelectedIndex].Value));
            iDX1 = ReturnDDLIndex(ddlSQ1, iQID1.ToString());
        }
        if (ddlSQ2.SelectedIndex > 0)
        {
            iQID2 = (ddlSQ2.Items[ddlSQ2.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ2.Items[ddlSQ2.SelectedIndex].Value));
            iDX2 = ReturnDDLIndex(ddlSQ2, iQID2.ToString());
        }
        if (ddlSQ3.SelectedIndex > 0)
        {
            iQID3 = (ddlSQ3.Items[ddlSQ3.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ3.Items[ddlSQ3.SelectedIndex].Value));
            iDX3 = ReturnDDLIndex(ddlSQ3, iQID3.ToString());
        }

        //System.Diagnostics.Debug.WriteLine(string.Format("Values: {0}, {1}, {2}", iQID1, iQID2, iQID3));

        //Populate Drop Down List (DDL) and select the original value if available, otherwise select 0
        PopulateDDL(ddlSQ1, iQID2, iQID3);
        ddlSQ1.SelectedIndex = ReturnDDLIndex(ddlSQ1, iQID1.ToString());
        PopulateDDL(ddlSQ3, iQID1, iQID2);
        ddlSQ3.SelectedIndex = ReturnDDLIndex(ddlSQ3, iQID3.ToString());
        txtSA2.Text = "";
    }

    protected void ddlSQ3_SelectedIndexChanged(object sender, EventArgs e)
    {
        //KEEP TRACK OF INDEX OF SELECTED VALUE (USED TO REASSIGN WHEN DROP DOWN CONTENT CHANGES)
        if (ddlSQ1.SelectedIndex > 0)
        {
            iQID1 = (ddlSQ1.Items[ddlSQ1.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ1.Items[ddlSQ1.SelectedIndex].Value));
            iDX1 = ReturnDDLIndex(ddlSQ1, iQID1.ToString());
        }
        if (ddlSQ2.SelectedIndex > 0)
        {
            iQID2 = (ddlSQ2.Items[ddlSQ2.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ2.Items[ddlSQ2.SelectedIndex].Value));
            iDX2 = ReturnDDLIndex(ddlSQ2, iQID2.ToString());
        }
        if (ddlSQ3.SelectedIndex > 0)
        {
            iQID3 = (ddlSQ3.Items[ddlSQ3.SelectedIndex].Value == "-1" ? 0 : int.Parse(ddlSQ3.Items[ddlSQ3.SelectedIndex].Value));
            iDX3 = ReturnDDLIndex(ddlSQ3, iQID3.ToString());
        }

        //System.Diagnostics.Debug.WriteLine(string.Format("Values: {0}, {1}, {2}", iQID1, iQID2, iQID3));

        //Populate Drop Down List (DDL) and select the original value if available, otherwise select 0
        PopulateDDL(ddlSQ1, iQID2, iQID3);
        ddlSQ1.SelectedIndex = ReturnDDLIndex(ddlSQ1, iQID1.ToString());
        PopulateDDL(ddlSQ2, iQID1, iQID3);
        ddlSQ2.SelectedIndex = ReturnDDLIndex(ddlSQ2, iQID2.ToString());
        txtSA3.Text = "";
    }

    private bool UserInfoInUse(string pUserInfo, UserInfoType UInfoType, out string MsgOut)
    {
        bool bReturn = false;
        string sMsg = "";
        int iRes = 0;

        DataTable dt = new DataTable();
        SqlConnection con = new SqlConnection(connStr);

        if (Page.IsPostBack)
        {
            //RETURN_VALUE - HOLDS THE INTEGER RETURN VALUE FROM THE PROCEDURE (0,1,2 or 3) - EACH HAVE MEANING 
            //  0 - Not In Use, 1 - In Use 

            SqlParameter parRet = new SqlParameter("returnVal", SqlDbType.Int) { Direction = ParameterDirection.ReturnValue};
            SqlParameter parOut = new SqlParameter("@MSG_OUT", SqlDbType.VarChar) {Direction = ParameterDirection.Output, Size = 255};
            SqlCommand com = new SqlCommand("csp_CheckLoginAvailable") {CommandType = CommandType.StoredProcedure, Connection = con};
            com.Parameters.AddWithValue("@USER_INFO", pUserInfo);
            com.Parameters.AddWithValue("@IGNORE_UID", "");

            switch (UInfoType)
            {
                case UserInfoType.Email:
                    com.Parameters.AddWithValue("@USER_INFO_TYPE", "E");
                    com.Parameters.Add(parOut);
                    com.Parameters.Add(parRet);
                    con.Open();
                    com.ExecuteNonQuery();
                    iRes = (int)com.Parameters["returnVal"].Value;
                    sMsg = (string)com.Parameters["@MSG_OUT"].Value;
                    con.Close();
                    break;
                case UserInfoType.UserName:
                    com.Parameters.AddWithValue("@USER_INFO_TYPE", "U");
                    com.Parameters.Add(parOut);
                    com.Parameters.Add(parRet);
                    con.Open();
                    com.ExecuteNonQuery();
                    iRes = (int)com.Parameters["returnVal"].Value;
                    sMsg = (string)com.Parameters["@MSG_OUT"].Value;
                    con.Close();
                    break;
                default:
                    sMsg = "Undefined [UserInfoType]. Defaulting to False";
                    break;
            }

            if (iRes == 1)
            {
                //System.Diagnostics.Debug.WriteLine(String.Format("Message: {0} - \"{1}\"", iRes, sMsg.ToString()));
                bReturn = true;
            }
        }


        MsgOut = sMsg;
        return bReturn;
    }

    protected void cvUserName_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string MsgOut = "";
        if (txtUserName.Text.ToString().Trim() == "")
        {
            args.IsValid = false;
            cvUserName.IsValid = false;
            icnUserName.ImageUrl = "/Images/icons/error1.png";
            lblUNMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#FFDD44");
            lblUNMsg.Attributes["style"] = "visibility: hidden;";
            lblUNMsg.Text = "";
        }
        else if (UserInfoInUse(txtUserName.Text.ToString().Trim(),UserInfoType.UserName,out MsgOut))
        {
            //User ID or email is in use already and not available
            args.IsValid = false;
            cvUserName.IsValid = false;
            
            icnUserName.ImageUrl = "/Images/icons/warn1.png";
            icnUserName.Attributes["style"] = "visibility: visible;";

            lblUNMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#FFDD44");
            lblUNMsg.Attributes["style"] = "visibility: visible; font-weight: bold;";
            lblUNMsg.Text = MsgOut;
        } else
        {
            icnUserName.ImageUrl = "/Images/icons/error1.png";
            icnUserName.Attributes["style"] = "visibility: hidden;";
            lblUNMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#000000");

            lblUNMsg.Attributes["style"] = "visibility: hidden;";
            lblUNMsg.Text = "";
        }
        //System.Diagnostics.Debug.WriteLine(string.Format("In cvUserName: Args({0})",Page.IsValid) );
    }

    protected void cvPhone_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sPNum = txtPhone.Text.ToString().Trim();

        if (!Regex.IsMatch(sPNum, @"^\d+$") || sPNum == "" || sPNum.Length < 10)
        {
            args.IsValid = false;
            cvPhone.IsValid = false;
            icnPhone.Attributes["style"] = "visibility: visible;";
        }
        else
        {
            icnPhone.Attributes["style"] = "visibility: hidden;";
        }
    }

    protected void cvFName_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtFName.Text.ToString().Trim();

        if (!Regex.IsMatch(sTxt, @"^[a-z A-Z]*$") || sTxt == "" || sTxt.Length < 2)
        {
            args.IsValid = false;
            cvFName.IsValid = false;
            icnFName.Attributes["style"] = "visibility: visible;";
        }
        else
        {
            icnFName.Attributes["style"] = "visibility: hidden;";
        }
    }

    protected void cvLName_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtLName.Text.ToString().Trim();

        if (!Regex.IsMatch(sTxt, @"^[a-z A-Z]*$") || sTxt == "" || sTxt.Length < 2)
        {
            args.IsValid = false;
            cvLName.IsValid = false;
            icnLName.Attributes["style"] = "visibility: visible;";
        }
        else
        {
            icnLName.Attributes["style"] = "visibility: hidden;";
        }
    }

    protected void cvEML1_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtEML1.Text.ToString().Trim();
        string MsgOut = "";


        if (UserInfoInUse(txtEML1.Text.ToString().Trim(), UserInfoType.Email, out MsgOut))
        {
            //User ID or email is in use already and not available
            args.IsValid = false;
            cvEML1.IsValid = false;

            icnEML1.ImageUrl = "/Images/icons/warn1.png";
            icnEML1.Attributes["style"] = "visibility: visible;";

            lblMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#FFDD44");
            lblMsg.Attributes["style"] = "visibility: visible; font-weight: bold;";
            lblMsg.Text = MsgOut;
        }
        else
        {
            lblMsg.Attributes["style"] = "visibility: hidden;";
            lblMsg.Text = "";
            icnEML1.ImageUrl = "/Images/icons/error1.png";
            icnEML1.Attributes["style"] = "visibility: hidden;";

            if ((!Regex.IsMatch(sTxt, @"^[a-zA-Z0-9@._]*$") || sTxt == "") || sTxt.Length < 6)
            {
                args.IsValid = false;
                cvEML1.IsValid = false;
                icnEML1.Attributes["style"] = "visibility: visible;";
            }
            else if (txtEML2.Text.ToString().Trim() != sTxt && sTxt != "")
            {
                args.IsValid = false;
                cvEML2.IsValid = false;
                icnEML2.ImageUrl = "./Images/icons/warn1.png";
                icnEML2.Attributes["style"] = "visibility: visible;";
            }
            else
            {
                icnEML1.Attributes["style"] = "visibility: hidden;";
                lblMsg.Text = "";
                lblMsg.Attributes["style"] = "visibility: hidden;";
            }
        }
        //System.Diagnostics.Debug.WriteLine(string.Format("In cvEML1: Args({0})",Page.IsValid) );
    }

    protected void cvEML2_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtEML2.Text.ToString().Trim();

        if (cvEML1.IsValid)
        {
            if ((!Regex.IsMatch(sTxt, @"^[a-zA-Z0-9@._]*$") || sTxt == "") || sTxt.Length < 6)
            {
                args.IsValid = false;
                cvEML2.IsValid = false;
                icnEML2.Attributes["style"] = "visibility: visible;";
            }
            else if (txtEML1.Text.ToString().Trim() != sTxt && (sTxt != "" || txtEML1.Text.ToString().Trim() != ""))
            {
                args.IsValid = false;
                cvEML2.IsValid = false;
                icnEML2.ImageUrl = "./Images/icons/warn1.png";
                icnEML2.Attributes["style"] = "visibility: visible;";
            }
            else
            {
                icnEML2.Attributes["style"] = "visibility: hidden;";
            }
        }
        //System.Diagnostics.Debug.WriteLine(string.Format("In cvEML2: Args({0})", Page.IsValid));
    }

    protected void cvPWD1_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtPWD1.Text.ToString().Trim();
        string MsgOut = "";


        if ((!Regex.IsMatch(sTxt, @"^[a-zA-Z0-9@._]*$") || sTxt == "") || sTxt.Length < 6)
        {
            args.IsValid = false;
            cvPWD1.IsValid = false;
            icnPWD1.Attributes["style"] = "visibility: visible;";
        }
        else if (txtPWD2.Text.ToString().Trim() != sTxt && sTxt != "")
        {
            args.IsValid = false;
            cvPWD2.IsValid = false;
            icnPWD2.ImageUrl = "./Images/icons/warn1.png";
            icnPWD2.Attributes["style"] = "visibility: visible;";
        }
        else
        {
            icnPWD1.Attributes["style"] = "visibility: hidden;";
        }
        //System.Diagnostics.Debug.WriteLine(string.Format("In cvPWD1: Args({0})",Page.IsValid) );
    }

    protected void cvPWD2_ServerValidate(object source, ServerValidateEventArgs args)
    {
        string sTxt = txtPWD2.Text.ToString().Trim();
        string MsgOut = "";


        if ((!Regex.IsMatch(sTxt, @"^[a-zA-Z0-9@._]*$") || sTxt == "") || sTxt.Length < 6)
        {
            args.IsValid = false;
            cvPWD2.IsValid = false;
            icnPWD2.Attributes["style"] = "visibility: visible;";
        }
        else if (txtPWD1.Text.ToString().Trim() != sTxt && (sTxt != "" || txtPWD1.Text.ToString().Trim() != ""))
        {
            args.IsValid = false;
            cvPWD2.IsValid = false;
            icnPWD2.ImageUrl = "./Images/icons/warn1.png";
            icnPWD2.Attributes["style"] = "visibility: visible;";
        }
        else
        {
            icnPWD2.Attributes["style"] = "visibility: hidden;";
        }
        //System.Diagnostics.Debug.WriteLine(string.Format("In cvPWD1: Args({0})",Page.IsValid) );
    }
}
 