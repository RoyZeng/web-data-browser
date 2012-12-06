<%@ page language="java" contentType="text/html; charset=utf-8" pageEncoding="UTF-8" isELIgnored="false"%>
<%@ page import="java.util.*"%>
<%@ page import="java.sql.*"%>
<%@ page import="java.io.*"%>
<!DOCTYPE HTML>
<html>
  <head>
    <title>WEB DATA BROWSER</title>
    <style>
fieldset {
  padding:2px;
  margin:5px;
  border:#06c solid 1px;
}
legend {
  color:#06c;
  font-weight:600;
}   
    </style>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  </head>
  <body>
  <!-- v1.1.8 -->
  <!-- by cong -->
  <%
  Connection connection = null;
  Statement st = null;
  boolean no_sql = false;
  boolean display_clob = false;
  StringBuffer error_message = new StringBuffer();
  StringBuffer results = new StringBuffer();
  StringBuffer info_message = new StringBuffer();
  java.util.Date startDate = new java.util.Date();
  
  int limit_rows = 200;
  int limit_clob = 400;
  if(request.getParameter("limit_rows") != null && request.getParameter("limit_rows").trim().length()>0){
    limit_rows = Integer.parseInt(request.getParameter("limit_rows"));
  }
  if(request.getParameter("limit_clob") !=null && request.getParameter("limit_clob").trim().length()>0){
    limit_clob = Integer.parseInt(request.getParameter("limit_clob"));
  }
  
  String password = request.getParameter("password");
  String sql_mode = request.getParameter("sql_mode");
  if(sql_mode == null){
    sql_mode = "is_select";
  }
  String sql_input = request.getParameter("sql_input");
  if(sql_input == null || sql_input.trim().length() ==0){
    no_sql = true;
    sql_input = "select current date from sysibm.sysdummy1";
  }  
  if("is_select".equals(sql_mode)){
    String temp = sql_input.toUpperCase();
  if(temp.indexOf("DELETE")>-1 || temp.indexOf("UPDATE") > -1 || temp.indexOf("INSERT") > -1){
    error_message.append("cann't update data when in select mode\n");
    error_message.append("sql_input : " + sql_input);
    sql_input = "select current date from sysibm.sysdummy1";
  }
  if(temp.indexOf("DROP")>-1 || temp.indexOf("ALTER") > -1 ){
    error_message.append("cann't modify table when in select mode\n");
    error_message.append("sql_input : " + sql_input);
    sql_input = "select current date from sysibm.sysdummy1";
  }
  }
  if("is_update".equals(sql_mode)){
    String temp = sql_input.toUpperCase();
  if(temp.indexOf("DROP")>-1 || temp.indexOf("ALTER") > -1 ){
    error_message.append("cann't modify table when in update mode\n");
    error_message.append("sql_input : " + sql_input);
    sql_input = "select current date from sysibm.sysdummy1";
    }
  }

  String connection_mode = request.getParameter("connection_mode");
  if(connection_mode == null || connection_mode.trim().length() ==0){
    connection_mode = "from_springbean";
  }
  
  String bean_name = request.getParameter("bean_name");
  if(bean_name == null || bean_name.trim().length() == 0){
    bean_name = "dataSource";
  }
  
  String jdbc_driver = request.getParameter("jdbc_driver");
  if(jdbc_driver == null || jdbc_driver.trim().length() == 0){
    jdbc_driver = "com.ibm.db2.jcc.DB2Driver";
  }
  
  String jdbc_url = request.getParameter("jdbc_url");
  if(jdbc_url == null || jdbc_url.trim().length() == 0){
    jdbc_url = "jdbc:db2://182.247.251.174:60000/htms";
  }
  
  String jdbc_user = request.getParameter("jdbc_user");
  if(jdbc_user == null || jdbc_user.trim().length() ==0){
    jdbc_user = "sdsp";
  }
  
  String jdbc_password = request.getParameter("jdbc_password");
  if(jdbc_password == null || jdbc_password.trim().length() == 0){
    jdbc_password = "sdsp";
  }
  
  String jndi_name = request.getParameter("jndi_name");
  if(jndi_name == null || jndi_name.trim().length() ==0){
    jndi_name = "jdbc/htms_datasource";
  }
  
  String catalog_name = request.getParameter("catalog_name");
  if(catalog_name != null && catalog_name.trim().length() == 0){
    catalog_name = null;
  }
  String schema_name = request.getParameter("schema_name");
  if(schema_name != null && schema_name.trim().length() ==0){
    schema_name = null;
  }
  String table_name = request.getParameter("table_name");
  
  if(request.getParameter("display_clob") != null){
    display_clob = true;
  }
  
  getJVMInfo(info_message);
  if(!login(password)){
    error_message.append("invalid password");
  }else if(no_sql && !"is_info".equals(sql_mode)){
    error_message.append("no sql input");
  }else{
    try{
      connection  = getConnection(request, info_message);//Pay attection parameters are retrieve from reqeust diretly
      if("is_info".equals(sql_mode)){
        DatabaseMetaData md = connection.getMetaData();
        if(table_name != null && table_name.trim().length() !=0){
          getTableInfo(md, catalog_name, schema_name, table_name, results, limit_rows);
        }else{
          getTables(md, catalog_name, schema_name, results, limit_rows);
        }
      }else{
        st = connection.createStatement();
        String analysedSQL = analyseSQL(sql_input);
        results.append("The query is " + analysedSQL);
        boolean execute_return = st.execute(analysedSQL);
        if(execute_return){
          ResultSet rs = st.getResultSet();
          results.append("<br>The query results: <br>");
          getTableData(rs, results, limit_rows, display_clob, limit_clob);
        }else{
          error_message.append("effected rows " + st.getUpdateCount());
        }
      }
    }catch(Exception e){
      error_message.append(exception2String(e));
    }finally{
      try{
        if(st != null){
          st.close();
        }
      }catch(Exception ee){
        error_message.append(exception2String(ee));
      }
      try{
        connection.close();
      }catch(Exception ee){
        error_message.append(exception2String(ee));
      }
    }
  }
  java.util.Date endDate = new java.util.Date();
  %>
  [<font color="red">Not to be used under production environment. Be carefull to modify data!</font>]<br>
  <form method="post">
    <table>
    <tr>
      <td>
      <table style="border-style:none">
        <tr>
          <td>
            <fieldset>
              <legend>SQL Mode </legend>
              <input name="sql_mode" type="radio" value="is_select" <%= "is_select".equals(sql_mode)?"checked":""%> title="select only"/>Query
              <input name="sql_mode" type="radio" value="is_update" <%= "is_update".equals(sql_mode)?"checked":""%> title="update or delete or insert "/>DML
              <input name="sql_mode" type="radio" value="is_ddl" <%= "is_ddl".equals(sql_mode)?"checked":""%> title="drop or alter table"/>DDL
              <input name="sql_mode" type="radio" value="is_info" <%= "is_info".equals(sql_mode)?"checked":""%> title="get information for table"/>Table
            </fieldset>
          </td>
          <td>
            <fieldset>
              <legend>Connection Mode</legend>
              <input name="connection_mode" type="radio" value="from_jdbc"  <%= "from_jdbc".equals(connection_mode)?"checked":""%> title="get connection using jdbc"/>JDBC
              <input name="connection_mode" type="radio" value="from_springbean" <%= "from_springbean".equals(connection_mode)?"checked":""%> title="get connection from spring datasource bean"/>Spring
              <input name="connection_mode" type="radio" value="from_jndi" <%= "from_jndi".equals(connection_mode)?"checked":""%> title="get connection by jndi name from app server"/>JNDI
            </fieldset>
          </td>
        </tr>
      </table>
      <table style="border-style:none">
        <tr>
          <td>
            <fieldset>
              <legend>JDBC Mode</legend>
              *Driver:<input name="jdbc_driver" size="24" value="<%= jdbc_driver%>" />
              *URL:<input name="jdbc_url" size="40" value="<%= jdbc_url%>" />
              User:<input name="jdbc_user" size="10" value="<%= jdbc_user%>"/>
              Password:<input name="jdbc_password"  size="10" type="password" value="<%= jdbc_password%>" />
            </fieldset>
          </td>
        </tr>
      </table>
      <table style="border-style:none">
        <tr>
          <td>
            <fieldset>
              <legend>Spring Mode</legend>
              *Bean Name:<input name="bean_name" size="10" value="<%= bean_name%>"/><br>
            </fieldset>
          </td>
          <td>
            <fieldset>
              <legend>JNDI Mode</legend>
              *JNDI Name:<input name="jndi_name" value="<%= jndi_name%>" />            
            </fieldset>
          </td>
          <td>
            <fieldset>
              <legend>Table Mode</legend>
              Catalog:<input name="catalog_name" size="8" value="<%= catalog_name==null?"":catalog_name%>" title="leave blank if you don't know"/>
              *Schema:<input name="schema_name" size="8" value="<%= schema_name==null?"":schema_name%>" />
              Table:<input name="table_name" type="text" size="18" value="<%= table_name==null?"":table_name%>" title="Case sensitive, perhaps always upper case for db2. If leave blank will list table names under the schema"/>
            </fieldset>
          </td>
        </tr>
      </table>
      <table  style="border-style:none">
        <tr valign="top">
          <td>
            <fieldset>
              <legend>SQL ( "--" means comment)</legend>
              <textarea name="sql_input" cols="120" rows="5"><%= sql_input==null?"":sql_input%></textarea>
              <br>
              <input name="btn_execute" type="submit" value="Execute" style="color:#ffffff;background-color:#1d5987;"/>
              Limit rows : <input name="limit_rows" size="4" maxlength="5" value="<%= limit_rows%>" title="limit only display but not data return from database, so be carefull for you sql statement. Too many rows will use massive memory and slow down the app server"/> | 
              <input name="display_clob" type="checkbox" value="display_clob" <%= display_clob?"checked='checked'":""%>>Display the CLOB from 1 to <input name="limit_clob" size="4" value="<%= limit_clob%>" /> characters  
               | "Dynamic" Password <input name="password", size="8" type="password" value="<%= password == null? "":password%>" title='"dynamic" password'/>
            </fieldset>
          </td>
        </tr>
      </table>
    </td>
    <td>
        <fieldset>
            <legend>Other Info</legend>
            <%= info_message.length()==0?"Some thing will be displayed here":"<pre style='margin:0px;'>" + info_message.toString() + "</pre>"%>
          </fieldset>
    </td>
  </tr>
  </table>
  </form>
  elapsed time <%= (endDate.getTime() - startDate.getTime())%> ms.<br>
  <font color="red">
  <%= error_message.length()==0?"":"<pre style='margin:0px;'>" + error_message.toString() + "</pre>"%>
  </font>
  <%= results.length()==0?"":results.toString()%>
  <br>
  <a href="http://code.google.com/p/web-data-browser/" target="_blank">Hosted at code.google.com</a>
 </body>
</html>
<%!
  static String[] colors={"#efefef","#dddddd"};
  static String[] passwords = {"bai","ri","yi","shan","jin","huang","he","ru","hai","liu","yu","qiong","qian","li","mu","geng","shang","yi","ceng","lou"};
  private boolean login(String input){
    Calendar rightNow = Calendar.getInstance();
    int hour = rightNow.get(Calendar.HOUR_OF_DAY);
    return passwords[hour - 1].equals(input);
  }
  private String exception2String(Exception e){
    ByteArrayOutputStream baos = new ByteArrayOutputStream();
    PrintStream ps = new PrintStream(baos);
    e.printStackTrace(ps);
    String result = baos.toString();
    ps.close();
    return result;
  }
  
  private void getJVMInfo(StringBuffer info_message){
    info_message.append("java heap(M):");
    java.lang.management.MemoryMXBean m_mbean = java.lang.management.ManagementFactory.getMemoryMXBean();
    java.lang.management.MemoryUsage m_usage = m_mbean.getHeapMemoryUsage();
    info_message.append("\n  init = " + tom(m_usage.getInit()));
    info_message.append("\n  max = " + tom(m_usage.getMax()));
    info_message.append("\n  used = " + tom(m_usage.getUsed()));
    info_message.append("\njava non heap(M):");
    m_usage = m_mbean.getNonHeapMemoryUsage();
    info_message.append("\n  init = " + tom(m_usage.getInit()));
    info_message.append("\n  max = " + tom(m_usage.getMax()));
    info_message.append("\n  used = " + tom(m_usage.getUsed()));
  }
  
  private void getTables(DatabaseMetaData md, String catalog_name, String schema_name, StringBuffer results, int limit_rows) throws Exception{
    results.append("Tables under schema " + schema_name + "<br>");
    ResultSet rs = md.getTables(catalog_name, schema_name, null, null);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();    
  }
  
  private void getTableInfo(DatabaseMetaData md, String catalog_name, String schema_name, String table_name, StringBuffer results, int limit_rows) throws Exception{
    results.append("Column information about " + (schema_name==null?"": schema_name+ ".") + table_name + "<br>");
    ResultSet rs = md.getColumns(catalog_name, schema_name, table_name, null);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();
        
    results.append("<br>Primary keys information about " + (schema_name==null?"": schema_name+ ".") + table_name + "<br>");
    rs = md.getPrimaryKeys(catalog_name, schema_name, table_name);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();
        
    results.append("<br>Index information about " + (schema_name==null?"": schema_name+ ".") + table_name + "<br>");
    rs = md.getIndexInfo(catalog_name, schema_name, table_name, false, true);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();
        
    results.append("<br>Imported keys information about " + (schema_name==null?"": schema_name+ ".")+ table_name + "<br>");
    rs = md.getImportedKeys(catalog_name, schema_name, table_name);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();
        
    results.append("<br>Exported keys information about " + (schema_name==null?"": schema_name+ ".") + table_name + "<br>");
    rs = md.getExportedKeys(catalog_name, schema_name, table_name);
    getTableData(rs, results, limit_rows, false, 0);
    rs.close();
  }
  

  
  private void getTableData(ResultSet rs, StringBuffer results, int limit_rows, boolean display_clob, int limit_clob) throws Exception{
    ResultSetMetaData metaData = rs.getMetaData();
    int columnCount = metaData.getColumnCount();
    results.append("<table style='border:#06c solid 1px;'>\n");
    results.append("<tr style='color:#ffffff;background-color:#003366; text-align: center;'>\n");
    results.append("<td style='background-color:#003366'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>\n");
    for(int i=1; i<=columnCount; i++){
      results.append("<td>");
      results.append(metaData.getColumnLabel(i));
      results.append("</td>\n");
    }
    results.append("</tr>\n");
  
    int rowNumber = 0;
    boolean limited = false;
    while(rs.next()){
      rowNumber ++;
      if(rowNumber > limit_rows){
        results.append("</table>\n");
        results.append("<font color='red'>Note: Some data are not displayed because of row limit ["+ limit_rows + "]</font><br>");
        limited = true;
        break;
      }
      results.append("<tr style='background-color:"+ colors[rowNumber % 2]+";'>\n");
      results.append("<td style='color:#ffffff;background-color:#003366;text-align: right;'>"+ rowNumber +"</td>\n");
      for(int i=1; i<=columnCount; i++){
        int type= metaData.getColumnType(i);
        results.append("<td>");
        if(isBigData(type)){
          if(type == Types.CLOB && display_clob){
            Clob clob = rs.getClob(i);
            if(clob == null){
              results.append("&lt;NULL CLOB&gt;");
            }else{
              results.append(clob.getSubString(1, limit_clob)+"[Total "+ clob.length() +" chars]");
              //clob.free(); //maybe throw exception because some driver does not implemeted this method
            }
          }else{
            results.append("&lt;LOB&gt;");
          }
        }else{
          results.append(rs.getString(i) == null?"&lt;null&gt;" : escapeHtml(rs.getString(i)));
        }
        results.append("</td>\n");
      }
      results.append("</tr>\n");
    }
    if(!limited){
      results.append("</table>\n");
    }
  }
  
  private boolean isBigData(int type){
    if(type == Types.BLOB || type == Types.CLOB){
      return true;
    }else{
      return false;
    }
  }
  
  private Connection getConnection(ServletRequest request, StringBuffer info_message) throws Exception{
    String connection_mode = request.getParameter("connection_mode");
    Connection connection = null;
    if("from_springbean".equals(connection_mode)){
      connection =  getConnectionFromDataSource(request.getParameter("bean_name"), info_message);
    }else if("from_jdbc".equals(connection_mode)){
      String driver = request.getParameter("jdbc_driver");
      String url = request.getParameter("jdbc_url");
      String user = request.getParameter("jdbc_user");
      String password = request.getParameter("jdbc_password");
      connection = getConnectionFromJDBC(driver, url, user, password, info_message);
    }else if("from_jndi".equals(connection_mode)){
      String jndiName = request.getParameter("jndi_name");
      connection = getConnectionFromJNDI(jndiName, info_message);
    }
    return connection;
  }
  
  private Connection getConnectionFromDataSource(String beanName, StringBuffer info_message) throws Exception{
    org.springframework.context.ApplicationContext ctx = org.springframework.web.context.support.WebApplicationContextUtils.getRequiredWebApplicationContext(getServletContext());
    Object object = ctx.getBean(beanName);
    if(object instanceof org.apache.commons.dbcp.BasicDataSource){
      org.apache.commons.dbcp.BasicDataSource bds = (org.apache.commons.dbcp.BasicDataSource)object;
      info_message.append("\ndbcp datasource info:");
      info_message.append("\n * getNumActive = " + bds.getNumActive());  
      info_message.append("\n * getNumIdle = " + bds.getNumIdle());   
      //info_message.append("\n getInitialSize = " + bds.getInitialSize());
      info_message.append("\n getMaxActive = " + bds.getMaxActive());    
      info_message.append("\n getMaxIdle = " + bds.getMaxIdle());    
      info_message.append("\n getMaxWait = " + bds.getMaxWait() + " ms");  
      info_message.append("\n getMinIdle = " + bds.getMinIdle());  
      info_message.append("\n getTestOnBorrow = " + bds.getTestOnBorrow());  
      info_message.append("\n getRemoveAbandoned = " + bds.getRemoveAbandoned());  
      info_message.append("\n getRemoveAbandonedTimeout = " + bds.getRemoveAbandonedTimeout() + " s");    
      info_message.append("\n getValidationQuery = " + bds.getValidationQuery());        
    }
    javax.sql.DataSource dataSource = (javax.sql.DataSource)object;
    return dataSource.getConnection();
  }
  
  private Connection getConnectionFromJDBC(String driverClass, String url, String user, String password, StringBuffer info_message) throws Exception{
    Driver driver = (Driver)Class.forName(driverClass).newInstance();
    info_message.append("jdbc driver info:");
    info_message.append("\n majorversion = " + driver.getMajorVersion());
    info_message.append("\n minorverion = " + driver.getMinorVersion());
    return DriverManager.getConnection(url, user, password);
  }
  
  private Connection getConnectionFromJNDI(String jndiName, StringBuffer info_message) throws Exception{
    javax.naming.InitialContext ctx = new javax.naming.InitialContext();  
    javax.sql.DataSource dataSource = (javax.sql.DataSource)ctx.lookup(jndiName);
    return dataSource.getConnection();
  }
  
  private String analyseSQL(String sql_input){
    String[] lines = sql_input.split("\\n");
    StringBuffer results = new StringBuffer();
    for(int i=0; i< lines.length; i++){
      if(!lines[i].trim().startsWith("--")){
        results.append(lines[i] + "\n");
      }
    }
    return results.toString();
  }
  
  private String escapeHtml(String input){
    //return input;
    return org.apache.commons.lang.StringEscapeUtils.escapeHtml(input);
  }
  long mm = 1024*1024;
  long tom(long input){
    return input / mm;
  }  
%>