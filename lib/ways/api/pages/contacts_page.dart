/*
 * Copyright 2018 Harsh Sharma
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:contacts/customviews/no_content_found.dart';
import 'package:contacts/customviews/progress_dialog.dart';
import 'package:contacts/models/base/event_object.dart';
import 'package:contacts/models/contact.dart';
import 'package:contacts/utils/constants.dart';
import 'package:contacts/ways/api/futures/api_futures.dart';
import 'package:contacts/ways/contact_avatar.dart';
import 'package:contacts/ways/contact_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

class ContactPage extends StatefulWidget {
  List<Contact> contactList;
  ContactPageState _contactPageState;

  ContactPage({this.contactList});

  @override
  createState() =>
      _contactPageState = new ContactPageState(contactList: contactList);

  void reloadContactList() {
    _contactPageState.reloadContacts();
  }
}

class ContactPageState extends State<ContactPage> {
  static final globalKey = new GlobalKey<ScaffoldState>();

  ProgressDialog progressDialog = ProgressDialog.getProgressDialog(
      ProgressDialogTitles.LOADING_CONTACTS, false);

  RectTween _createRectTween(Rect begin, Rect end) {
    return new MaterialRectCenterArcTween(begin: begin, end: end);
  }

  static const opacityCurve =
      const Interval(0.0, 0.75, curve: Curves.fastOutSlowIn);

  List<Contact> contactList;

  ContactPageState({this.contactList});

  Widget contactListWidget;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 3.0;
    return new Scaffold(
      key: globalKey,
      body: loadList(),
      backgroundColor: Colors.grey[150],
    );
  }

  Widget loadList() {
    if (contactList != null) {
      contactListWidget = _buildContactList();
    } else {
      contactListWidget =
          NoContentFound(Texts.NO_CONTACTS, Icons.account_circle);
    }
    return new Stack(
      children: <Widget>[contactListWidget, progressDialog],
    );
  }

  Widget _buildContactList() {
    return new ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, i) {
        return _buildContactRow(contactList[i]);
      },
      itemCount: contactList.length,
    );
  }

  Widget _buildContactRow(Contact contact) {
    return new GestureDetector(
      onTap: () {
        _heroAnimation(contact);
      },
      child: new Card(
        margin: EdgeInsets.only(top: 10.0, bottom: 10.0),
        child: new Container(
          child: new Column(
            children: <Widget>[
              new Row(
                children: <Widget>[
                  contactAvatar(contact),
                  contactDetails(contact)
                ],
              ),
/*
            new Container(
              margin: EdgeInsets.only(top: 10.0),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  actionContainer(
                      Icons.visibility, Colors.blue[400], Actions.VIEW_CONTACT),
                  actionContainer(
                      Icons.edit, Colors.blueGrey[400], Actions.VIEW_CONTACT),
                  actionContainer(
                      Icons.delete, Colors.black, Actions.VIEW_CONTACT),
                ],
              ),
            )
*/
            ],
          ),
          margin: EdgeInsets.all(10.0),
        ),
      ),
    );
  }

  Widget contactAvatar(Contact contact) {
    return new Hero(
      tag: contact.id,
      child: new ContactAvatar(
        contact: contact,
      ),
      createRectTween: _createRectTween,
    );
  }

  Widget contactDetails(Contact contact) {
    return new Flexible(
        child: new Container(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          textContainer(contact.name, Colors.blue[400]),
          textContainer(contact.phone, Colors.blueGrey[400]),
          textContainer(contact.email, Colors.black),
        ],
      ),
      margin: EdgeInsets.only(left: 20.0),
    ));
  }

  Widget textContainer(String string, Color color) {
    return new Container(
      child: new Text(
        string,
        style: TextStyle(
            color: color, fontWeight: FontWeight.normal, fontSize: 16.0),
        textAlign: TextAlign.start,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      margin: EdgeInsets.only(bottom: 10.0),
    );
  }

  Widget actionContainer(IconData icon, Color color, String action) {
    return new Flexible(
        flex: 1,
        child: new GestureDetector(
          child: new Icon(
            icon,
            size: 30.0,
            color: color,
          ),
          onTap: () {
            setState(() {
              switch (action) {
                case Actions.VIEW_CONTACT:
                  break;
                case Actions.EDIT_OR_UPDATE_CONTACT:
                  break;
                case Actions.DELETE_CONTACT:
                  break;
              }
            });
          },
        ));
  }

  void _heroAnimation(Contact contact) {
    Navigator.of(context).push(
      new PageRouteBuilder<Null>(
        pageBuilder: (BuildContext context, Animation<double> animation,
            Animation<double> secondaryAnimation) {
          return new AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget child) {
                return new Opacity(
                  opacity: opacityCurve.transform(animation.value),
                  child: ContactDetails(contact),
                );
              });
        },
      ),
    );
  }

  void reloadContacts() {
    setState(() {
      progressDialog
          .showProgressWithText(ProgressDialogTitles.LOADING_CONTACTS);
      loadContacts();
    });
  }

  void loadContacts() async {
    EventObject eventObject = await getContacts();
    if (this.mounted) {
      setState(() {
        progressDialog.hideProgress();
        contactList = eventObject.object;
        switch (eventObject.id) {
//------------------------------------------------------------------------------
          case EventConstants.READ_CONTACTS_SUCCESSFUL:
            showSnackBar(SnackBarText.CONTACTS_LOADED_SUCCESSFULLY);
            break;
          case EventConstants.READ_CONTACTS_UN_SUCCESSFUL:
            showSnackBar(SnackBarText.UNABLE_TO_LOAD_CONTACTS);
            break;
          case EventConstants.NO_CONTACTS_FOUND:
            showSnackBar(SnackBarText.NO_CONTACTS_FOUND);
            break;
//------------------------------------------------------------------------------
          case EventConstants.NO_INTERNET_CONNECTION:
            contactListWidget = new NoContentFound(
                SnackBarText.NO_INTERNET_CONNECTION, Icons.signal_wifi_off);
            showSnackBar(SnackBarText.NO_INTERNET_CONNECTION);
            break;
        }
      });
    }
  }

  void showSnackBar(String textToBeShown) {
    globalKey.currentState.showSnackBar(new SnackBar(
      content: new Text(textToBeShown),
    ));
  }
}
