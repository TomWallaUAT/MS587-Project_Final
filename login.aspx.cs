using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.SqlClient;
using System.Data;
using System.Configuration;

public partial class login : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        //System.Diagnostics.Debug.WriteLine("Page_Load");
    }

    private string SQLString(string sValue)
    {
        if (sValue is null)
        {
            sValue = "";
        }
        return "'" + sValue + "'";
    }

    protected void btnLogin_Click(object sender, EventArgs e)
    {
        string connStr = ConfigurationManager.ConnectionStrings["DBConn"].ConnectionString;
        string sMsg = "";
        string sUID = "";
        int iRes = 0;

        if (Page.IsPostBack)
        {
            if (Page.IsValid)
            {
                DataTable dt = new DataTable();
                SqlConnection con = new SqlConnection(connStr);

                //RETURN_VALUE - HOLDS THE INTEGER RETURN VALUE FROM THE PROCEDURE (0,1,2 or 3) - EACH HAVE MEANING 
                //  0 -Invalid Login, 1 - Login Successful (Verified), 2=Login Successful (Not Verified)  / 3 - Account Locked (# min(s))
                SqlParameter parRet = new SqlParameter("returnVal", SqlDbType.Int);
                parRet.Direction = ParameterDirection.ReturnValue;

                //MSG_OUT - HOLDS THE MESSAGE FROM THE STORED PROCEDURE, SHOWS IN lblMsg
                SqlParameter parOut = new SqlParameter("@MSG_OUT", SqlDbType.VarChar);
                parOut.Direction = ParameterDirection.Output;
                parOut.Size = 255;

                //USER_ID - IF USER NAME/EMAIL RESOLVES TO A USER_ID, OTHERWISE HOLDS BLANK
                SqlParameter parOutUID = new SqlParameter("@UID_OUT", SqlDbType.VarChar);
                parOutUID.Direction = ParameterDirection.Output;
                parOutUID.Size = 60;
                
                //DATA BASE CALL TO THE PROCEDURE FOR LOGIN
                SqlCommand com = new SqlCommand("csp_LOGON_User");
                com.CommandType = CommandType.StoredProcedure;
                com.Connection = con;
                com.Parameters.AddWithValue("@USER_NM", txtLgn.Text.ToString());
                com.Parameters.AddWithValue("@USER_PWD", txtPwd.Text.ToString());
                com.Parameters.Add(parOut);
                com.Parameters.Add(parOutUID);
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
            else
            {
                lblMsg.ForeColor = System.Drawing.ColorTranslator.FromHtml("#BB2200");
                lblMsg.Text = "Invalid login. Please try again...";
            }
        }
    }

    protected void ResetCTRL()
    {
        //RESET CONTROLS
        txtLgn.Text = "Email or Username";
        txtPwd.Text = "";
        txtLgn.CssClass = "inputTxt280";
        txtPwd.CssClass = "inputTxt280";
    }

    protected void btnReset_Click(object sender, EventArgs e)
    {
        ResetCTRL();
    }

    protected void FocusMe(object sender, EventArgs e)
    {
        btnLogin.Focus();
    }

    protected void Page_Init(object sender, EventArgs e)
    {
        //System.Diagnostics.Debug.WriteLine("Page INIT");
    }
}