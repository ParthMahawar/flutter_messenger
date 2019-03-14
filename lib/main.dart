import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart' as ShadyContacts; //Name conflicts
import 'dart:async';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:sms/sms.dart';
import 'package:sms/contact.dart';
import 'dart:io';
//TODO: Add Notifications
void main(){
  runApp(new MessagingApp());
}

class MessagingApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: new Home()
    );
  }
}

class Home extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: (){
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => new NewThread())
          );
        },
      ),
      appBar: new AppBar(
        title: Text("Flutter Messenger"),
      ),
      body: new ChatList()
    );
  }
}

class ChatList extends StatefulWidget{
  @override
  ChatListState createState() => new ChatListState();
}

class ChatListState extends State{
  final searchController = TextEditingController();

  Future thread_list() async{
    SmsQuery query = new SmsQuery();
    final threads = await query.getAllThreads;
    return threads;
  }

  String CheckName(Contact contact){
    if(contact.fullName==null) return contact.address;
    else return contact.fullName;
  }

  List<SmsThread> GetThreads(List<SmsThread> threads){
    List<SmsThread> contactList = [];
    for(int i = 0; i<threads.length; i++){
      if(CheckName(threads.elementAt(i).contact).contains(searchController.text)){
        //print(CheckName(threads.elementAt(i).contact));
        contactList.add(threads.elementAt(i));
      }
    }
    return contactList;
  }

  Widget ShowContacts(threads){
    var toList = GetThreads(threads);
    //print(contacts);
    return Column(
      children: <Widget>[
        Expanded(
          child: ListTile(
            leading: Icon(Icons.search),
            title: TextField(
              controller: searchController,
              onChanged: (Text) {
                setState(() {});
              },
            ),
          )
        ),
        Expanded(
          flex: 8,
          child: ListView.builder(
            itemCount: toList.length,
            itemBuilder: (context, index){
              //print(contacts[index]);
              //print(searchController.text);
              //if(CheckName(threads.elementAt(index).contact).contains(searchController.text)){
                return Padding(
                  padding: EdgeInsets.all(5.0),
                  child: InkWell(
                    child: ListTile(
                      title: Text(CheckName(toList.elementAt(index).contact))
                    ),
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MessagingScreen(threadGiven:toList.elementAt(index))
                        )
                      );
                    },
                  )
                );
              //}
              //else return null;
            },
          )
        )
      ],
    );
  }

  @override

  Widget onContactsPermissionGiven(){
    return FutureBuilder(
      future: thread_list(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.hasData){
          return ShowContacts(snapshot.data);
        }
        else if(snapshot.hasError){
          print(snapshot.error);
        }
        else return CircularProgressIndicator();
      }
    );
  }

  Future checkContactsPermission() async{
    bool result = await SimplePermissions.checkPermission(Permission.ReadContacts);
    return result;
  }

  Future askForContacts() async{
    final res = SimplePermissions.requestPermission(Permission.ReadContacts);
    print("REQUEST IS "+ res.toString());
    return res;
  }

  Widget requestContactsPermission(){
    return FutureBuilder(
      future: askForContacts(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.hasData){
          if(snapshot.data==PermissionStatus.authorized){
            return onContactsPermissionGiven();
          }
          else return requestContactsPermission();
        }
        else if(snapshot.hasError){
          return Text(snapshot.error.toString());
        }
        else return CircularProgressIndicator();
      }
    );
  }

  Widget build(BuildContext context){
    return FutureBuilder(
      future: checkContactsPermission(),
      builder: (BuildContext context, AsyncSnapshot snapshot){
        if(snapshot.hasData){
          if(snapshot.data){
            return onContactsPermissionGiven();
          }
          else{
            return requestContactsPermission();
          }
        }
        else if(snapshot.hasError){
          return Text(snapshot.error.toString());
        }
        else return CircularProgressIndicator();
      },
    );
  }
}

class MessagingScreen extends StatefulWidget{
  SmsThread threadGiven;
  MessagingScreen({Key key, @required this.threadGiven}) : super(key:key);

  @override
  MessagingScreenState createState() => MessagingScreenState(thread:threadGiven);
}

class MessagingScreenState extends State{
  SmsThread thread;
  MessagingScreenState({Key key, @required this.thread});
  final inputController = TextEditingController();

  Widget NameOrNumber(Contact contact){
    if(contact.fullName==null) return Text(contact.address);
    else return Text(contact.fullName);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: NameOrNumber(thread.contact)
      ),
      body: FutureBuilder(
        future: getMessages(thread),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.hasData){
            return showMessages(snapshot.data);
          }
          else return CircularProgressIndicator();
        }
      )
    );
  }

  Future getMessages(SmsThread thread) async{
    SmsQuery query = new SmsQuery();
    List<SmsMessage> messages = await query.querySms(
      address: thread.address,
      kinds: [SmsQueryKind.Inbox, SmsQueryKind.Sent]
    );
    //var max = contact.phones();
    //print(max);

    return messages;
  }

  void SendMessage(String body, SmsThread thread) {
    SmsSender sender = new SmsSender();
    SmsMessage message = new SmsMessage(thread.address, body);

    message.onStateChanged.listen((state) {
      //sleep(Duration(seconds: 2));
      if(state==SmsMessageState.Sent){
        print(state.toString());
        setState(() {});
      }
    });
    
    sender.sendSms(message);
  }

  Widget showMessages(List<SmsMessage> messages){
    SmsReceiver receiver = new SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage msg){
      sleep(Duration(milliseconds: 50));
      setState(() {});
    });

    return Column(
      children: <Widget>[
        Expanded(
          flex: 13,
          child: ListView.builder(
            reverse: true,
            itemCount: messages.length,
            itemBuilder: (context, i){
              SmsMessage message = messages[i];

              Color color;
              var alignval;
              double padLeft = 10.0;
              double padRight = 10.0;

              if(message.kind == SmsMessageKind.Received){
                padRight = 75.0;
                alignval = Alignment.centerLeft;
                color = Colors.lightBlue;
              }
              else{
                padLeft = 75.0;
                alignval = Alignment.centerRight;
                color = Colors.lightGreen;
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(padLeft, 5.0, padRight, 5.0),
                child: Align(
                  alignment: alignval,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey, width: 2.0),
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                      color: color
                    ),
                    padding: EdgeInsets.all(5.0),
                    child: Text(message.body)
                  ),
                )
              );
            }
          )
        ),

        Expanded(
          flex: 2,
          child: ListTile(
            title: TextField(
              controller: inputController,
            ),
            trailing: InkWell(
              child: Icon(Icons.send),
              onTap: () => SendMessage(inputController.text, thread),
            ),
          )
        )
      ],
    );
  }
}

class NewThread extends StatefulWidget{
  NewThreadState createState() => new NewThreadState();
}

class NewThreadState extends State{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text("New Thread"),
      ),
      body: new ContactList()
    );
  }
}

class ContactList extends StatefulWidget{
  ContactListState createState() => new ContactListState();
}

class ContactListState extends State {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ListContacts(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return ShowContacts(snapshot.data);
        }
        return CircularProgressIndicator();
      },
    );
  }

  Future ListContacts() async{
    return await ShadyContacts.ContactsService.getContacts();
  }

  Widget ShowContacts(Iterable<ShadyContacts.Contact> contacts){
    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, i){
        var contact = contacts.elementAt(i);
        return ListTile(
          title: Text(contact.displayName),
          onTap: (){
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhoneNumbers(contact: contact)
              )
            );
          },
        );
      },
    );
  }
}

class PhoneNumbers extends StatelessWidget{
  final ShadyContacts.Contact contact;
  PhoneNumbers({Key key, @required this.contact}) : super(key:key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(contact.displayName),
      ),
      body: ListView.builder(
        itemCount: contact.phones.length,
        itemBuilder: (context, index){
          return Text(contact.phones.elementAt(index).value);
        },
      )
    );
  }
}
