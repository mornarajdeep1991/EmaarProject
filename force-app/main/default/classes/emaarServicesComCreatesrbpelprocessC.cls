//Generated by wsdl2apex

public class emaarServicesComCreatesrbpelprocessC {
    public class InvalidCustomerSecurityChkRequestType {
        public String ErrorMsg;
        private String[] ErrorMsg_type_info = new String[]{'ErrorMsg','http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0',null,'1','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0','true','true'};
        private String[] field_order_type_info = new String[]{'ErrorMsg'};
    }
    public class CustomerSecurityChkRequestType {
        public String UserName;
        public String FromOrderDate;
        public String ToOrderDate;
        private String[] UserName_type_info = new String[]{'UserName','http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0',null,'0','1','false'};
        private String[] FromOrderDate_type_info = new String[]{'FromOrderDate','http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0',null,'0','1','false'};
        private String[] ToOrderDate_type_info = new String[]{'ToOrderDate','http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0',null,'0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://emaar.services.com/CreateSRBPELProcess/customerSecurityChk/v1.0','true','true'};
        private String[] field_order_type_info = new String[]{'UserName','FromOrderDate','ToOrderDate'};
    }
}