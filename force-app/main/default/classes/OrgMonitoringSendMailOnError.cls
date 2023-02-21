public with sharing class OrgMonitoringSendMailOnError {
    @future   
    public static void sendEmail(String errorMsg) {

    // Get the User Id address of Organizaztion Apex Exception Email
    List <String> emailForError = new List<String>();
    String userId = ' ';
    try
    {
        if (  Test.isRunningTest() ) {
            userId = UserInfo.getUserId();
        } else { 
            ApexEmailNotification uId = [SELECT UserId FROM ApexEmailNotification where UserId !=NULL order by CreatedDate limit 1];
            userId = uId.UserId;
        }
        
        system.debug ('User Id : '+ userId);
        User user = [SELECT Email FROM User WHERE Id = :userId];
        String userEmail = user.Email;
        emailForError.add(userEmail);
        system.debug ('emailForError : '+ emailForError);
        // Create a new email message
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        // Set the recipient email address
        email.setToAddresses(emailForError);
        // Set the email subject
        email.setSubject('Error(s) when extracting data on EAGLES');
        // Set the email body
        email.setPlainTextBody(errorMsg);
        // Send the email if an email exists
        Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{ email });
        // Check if the email was sent successfully
        if (result[0].isSuccess()) {
            System.debug('Email sent successfully.');
        } else {
           System.debug('Email failed to send.');
          }
    } catch (QueryException qe) {
        system.debug ('Email not sent, Apex Email Notification is not set up : '+ qe);
      }
    }
}
    