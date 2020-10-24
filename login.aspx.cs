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
        //lblServerTime.Text = DateTime.Now.ToString();
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

        if (Page.IsPostBack)
        {
            if (Page.IsValid)
            {
                int iRes = 0;
                DataTable dt = new DataTable();
                SqlConnection con = new SqlConnection(connStr);
                SqlParameter parOut = new SqlParameter("@MSG_OUT", SqlDbType.VarChar);
                parOut.Direction = ParameterDirection.Output;
                parOut.Size = 255;
                

                SqlCommand com = new SqlCommand("csp_LOGON_User");
                com.CommandType = CommandType.StoredProcedure;
                com.Connection = con;

                com.Parameters.AddWithValue("@USER_NM", txtLgn.Text.ToString());
                com.Parameters.AddWithValue("@USER_PWD", txtPwd.Text.ToString());
                com.Parameters.Add(parOut);

                con.Open();
                object oRes = com.ExecuteScalar();
                string sMsg = (string)com.Parameters["@MSG_OUT"].Value;
                if (oRes != null)
                {
                    iRes = Convert.ToInt32(oRes);
                }
                lblMsg.Text = sMsg.ToString();
                con.Close();

                /*
                 * 
                 * 	@USER_NM		varchar(60),		--USER EMAIL or USER_NAME (EITHER OR)
	                @USER_PWD		varchar(40),		--USER EMAIL
	                @MSG_OUT
                 * */

            }
            else
            {
                lblMsg.Text = "Invalid login. Please try again...";
            }
        } 
    }

    protected void btnReset_Click(object sender, EventArgs e)
    {
        txtLgn.Text = "Email or Username";
        txtPwd.Text = "Password";
        txtLgn.CssClass = "inputTxt200";
        txtPwd.CssClass = "inputTxt200";
    }

    protected void FocusMe(object sender, EventArgs e)
    {
        btnLogin.Focus();
    }
}