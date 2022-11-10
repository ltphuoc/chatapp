import 'dart:html';

import 'package:chatapp/helper/helper_function.dart';
import 'package:chatapp/pages/chat_page.dart';
import 'package:chatapp/service/database_service.dart';
import 'package:chatapp/widgets/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  QuerySnapshot? searchSnapshot;
  QuerySnapshot? listSnapshot;
  bool hasUserSearched = false;
  String userName = "";
  bool isJoined = false;
  User? user;
  String? enrollKey;

  @override
  void initState() {
    super.initState();
    getCurrentUserIdAndName();
    getListGroup();
  }

  getListGroup({String name = ''}) async {
    await DatabaseService().getAllGroup(name).then((snapshot) {
      setState(() {
        listSnapshot = snapshot;
        isLoading = false;
      });
    });
  }

  getCurrentUserIdAndName() async {
    await HelperFunctions.getUserNameFromSF().then((value) {
      setState(() {
        userName = value!;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  String getName(String r) {
    return r.substring(r.indexOf("_") + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Search",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          getListGroup(name: value);
                        } else {
                          getListGroup();
                        }
                      },
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search groups....",
                          hintStyle:
                              TextStyle(color: Colors.white, fontSize: 14)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // initiateSearchMethod();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40)),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
                  )
                : groupList(),
          ],
        ),
      ),
    );
  }

  initiateSearchMethod() async {
    if (searchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService()
          .searchByName(searchController.text)
          .then((snapshot) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  bool isUserJoind(String id, List<dynamic> list) {
    for (int i = 0; i < list.length; i++) {
      if (list[i] == id) {
        return true;
      }
    }
    return false;
  }

  groupList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: listSnapshot!.docs.length,
        itemBuilder: (context, index) {
          return groupTile(
            userName,
            listSnapshot!.docs[index]['groupId'],
            listSnapshot!.docs[index]['groupName'],
            listSnapshot!.docs[index]['admin'],
            listSnapshot!.docs[index]['isPrivate'],
            listSnapshot!.docs[index]['enrollKey'],
            listSnapshot!.docs[index]['members'],
          );
        },
      ),
    );
  }

  joinedOrNot(String userName, String groupId, String groupName, String admin,
      bool isPrivate) async {
    await DatabaseService(uid: user!.uid)
        .isUserJoined(groupName, groupId, userName)
        .then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  Widget groupTile(String userName, String groupId, String groupName,
      String admin, bool isPrivate, String? enrollKey, List<dynamic> members) {
    // function to check whether user already exists in group
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title:
          Text(groupName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
          "Admin: ${getName(admin)} ${isPrivate ? "(Private)" : "Public"}"),
      trailing: InkWell(
          onTap: () async {
            if (!isUserJoind(user!.uid, members)) {
              if (isPrivate == true) {
                showEnrollDialog(
                    context, groupId, userName, groupName, enrollKey ?? '');
              } else {
                await DatabaseService(uid: user!.uid)
                    .toggleGroupJoin(groupId, userName, groupName);
                getListGroup();
                showSnackbar(
                    context, Colors.green, "Successfully joined he group");
                Future.delayed(const Duration(seconds: 1), () {
                  nextScreen(
                      context,
                      ChatPage(
                          groupId: groupId,
                          groupName: groupName,
                          userName: userName));
                });
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isUserJoind(user!.uid, members)
                  ? Colors.black
                  : Theme.of(context).primaryColor,
              border: Border.all(color: Colors.white, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              isUserJoind(user!.uid, members) ? "Joined" : "Join",
              style: TextStyle(color: Colors.white),
            ),
          )
          // : Container(
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(10),
          //       color: Theme.of(context).primaryColor,
          //     ),
          //     padding:
          //         const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          //     child: const Text("Join Now",
          //         style: TextStyle(color: Colors.white)),
          //   ),
          ),
    );
  }

  void showEnrollDialog(
    BuildContext context,
    String groupId,
    String userName,
    String groupName,
    String enrollKeyGroup,
  ) {
    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: ((context, setState) {
            return AlertDialog(
              title: Text(
                'Join $groupName',
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        enrollKey = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        hintText: "Enroll key",
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(10)),
                        errorBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.red),
                            borderRadius: BorderRadius.circular(20)),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Theme.of(context).primaryColor),
                            borderRadius: BorderRadius.circular(20))),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15)),
                  child: const Text("CANCEL"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (enrollKey == enrollKeyGroup) {
                      await DatabaseService(uid: user!.uid)
                          .toggleGroupJoin(groupId, userName, groupName)
                          .whenComplete(() {
                        showSnackbar(
                            context, Colors.green, "Join successfully.");
                        getListGroup();
                      });
                      Future.delayed(const Duration(seconds: 2), () {
                        nextScreen(
                            context,
                            ChatPage(
                                groupId: groupId,
                                groupName: groupName,
                                userName: userName));
                      });
                    } else {
                      showSnackbar(context, Colors.red,
                          "Enroll key is incorrect. Please try again.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      primary: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 15)),
                  child: const Text("JOIN"),
                )
              ],
            );
          }));
        });
  }
}
