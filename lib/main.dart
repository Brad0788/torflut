// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:get/get.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(const MyApp());
}

const fiveSeconds = const Duration(seconds: 5);

var _link;

Future<void> initUniLinks() async {
  // Platform messages may fail, so we use a try/catch PlatformException.
  try {
    _link = await getInitialLink();
    // Parse the link and warn the user, if it is not correct,
    // but keep in mind it could be `null`.
  } on PlatformException {
    // Handle exception by warning the user their action did not succeed
    // return?
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void initState() {
    initUniLinks();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Startup Name Generator',
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xff6750a4),
        accentColor: Color(0xff6750a4),
      ),
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: Home(),
    );
  }
}

class Home extends StatelessWidget {
  Home({super.key});
  final myController = TextEditingController(text: _link.toString());
  Future<http.Response> addTorrent(String magnet) {
    return http.post(
      Uri.parse('https://sndu46.deta.dev/check'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'magnet': magnet,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TorFlut'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb),
            onPressed: () {
              Get.changeThemeMode(
                  Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
            },
          ),
        ],
      ),
      body: const Center(
        child: TorrentsList(),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {},
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet<void>(
              context: context,
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              useRootNavigator: true,
              builder: (BuildContext context) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Add Torrent',
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: myController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Magnet Link',
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff6750a4)),
                          onPressed: () {
                            addTorrent(myController.text);
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
        tooltip: 'Increment Counter',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class TorrentsList extends StatefulWidget {
  const TorrentsList({super.key});

  @override
  State<TorrentsList> createState() => _TorrentsListState();
}

class _TorrentsListState extends State<TorrentsList> {
  var torrents;
  bool isChecked = false;

  Future<String> fetchTorrents() async {
    var response = await http.get(Uri.parse("https://sndu46.deta.dev/qbit"),
        headers: {"Accept": "application/json"});

    this.setState(() {
      torrents = json.decode(response.body);
    });
    return "Success!";
  }

  Future<http.Response> PauseTorrent(String hash) {
    return http.post(
      Uri.parse('https://sndu46.deta.dev/pause'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'hash': hash,
      }),
    );
  }

  Future<http.Response> ResumeTorrent(String hash) {
    return http.post(
      Uri.parse('https://sndu46.deta.dev/resume'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'hash': hash,
      }),
    );
  }

  Future<http.Response> DeleteTorrent(String hash) {
    return http.post(
      Uri.parse('https://sndu46.deta.dev/delete'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'hash': hash,
        'del': isChecked.toString(),
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future:
            Future.delayed(const Duration(seconds: 3), () => fetchTorrents()),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: torrents == null ? 0 : torrents["torrents"].length,
              itemBuilder: (context, i) {
                var sizeMb = (torrents["torrents"][i]["size"] / 1048576)
                    .toStringAsFixed(1);
                var sizeGb = (torrents["torrents"][i]["size"] / 1073741824)
                    .toStringAsFixed(2);
                var completedMb =
                    (torrents["torrents"][i]["completed"] / 1048576)
                        .toStringAsFixed(1);
                var completedGb =
                    (torrents["torrents"][i]["completed"] / 1073741824)
                        .toStringAsFixed(2);
                var progress = torrents["torrents"][i]["progress"] * 100;
                return Card(
                  child: InkWell(
                    onTap: (() {
                      showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                ListTile(
                                  leading: Icon(torrents["torrents"][i]
                                              ["state"] !=
                                          "Paused"
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  title: Text(torrents["torrents"][i]
                                              ["state"] !=
                                          "Paused"
                                      ? 'Pause'
                                      : 'Resume'),
                                  onTap: () {
                                    torrents["torrents"][i]["state"] != "Paused"
                                        ? PauseTorrent(
                                            torrents["torrents"][i]["hash"])
                                        : ResumeTorrent(
                                            torrents["torrents"][i]["hash"]);
                                    Navigator.pop(context);
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete),
                                  title: const Text('Delete'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      isChecked = false;
                                    });
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text("Delete Torrent?"),
                                            content: StatefulBuilder(builder:
                                                (BuildContext context,
                                                    StateSetter setState) {
                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                      "Are you sure you want to delete this torrent?"),
                                                  CheckboxListTile(
                                                    title: Text(
                                                        "Also delete the files on the disk?"),
                                                    checkColor: Colors.white,
                                                    value: isChecked,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        isChecked = value!;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              );
                                            }),
                                            actions: [
                                              TextButton(
                                                child: Text("Yes"),
                                                onPressed: () {
                                                  DeleteTorrent(
                                                      torrents["torrents"][i]
                                                          ["hash"]);
                                                  Navigator.pop(context);
                                                },
                                              ),
                                              TextButton(
                                                child: Text("No"),
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ],
                                          );
                                        });
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.list_alt),
                                  title: const Text('Details'),
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          });
                    }),
                    child: Column(children: <Widget>[
                      ListTile(
                        title: Text(torrents["torrents"][i]["name"]),
                        subtitle: Text(torrents["torrents"][i]["state"]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                        child: LinearProgressIndicator(
                          color: Color(0xff6750a4),
                          value: double.parse(
                              (torrents["torrents"][i]["progress"]).toString()),
                        ),
                      ),
                      ListTile(
                        title: torrents["torrents"][i]["size"] >= 1073741824
                            ? Text(completedGb +
                                " GB" +
                                " / " +
                                sizeGb +
                                " GB" +
                                " • " +
                                progress.toStringAsFixed(0) +
                                "%")
                            : Text(completedMb +
                                " MB" +
                                " / " +
                                sizeMb +
                                " MB" +
                                " • " +
                                progress.toStringAsFixed(0) +
                                "%"),
                        dense: true,
                      ),
                    ]),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        });
  }
}
