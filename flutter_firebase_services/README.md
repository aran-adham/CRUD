# Firebase Flutter Example

This Flutter project demonstrates Firebase integration for Firestore CRUD operations, Firebase Authentication (Auth) for user registration and login, and Firebase Storage for uploading images.

## Firestore CRUD Operations

## Create an instanse

````dart
Db db = Db();
````
### Create Document

To add a new document to a Firestore collection:

````dart
// Sample code for creating a document
await db.addDocument(
  collectionName: 'users',
  data: {'name': 'John Doe', 'age': 25},
);
````


### Read

to read all documents in a collection

````dart
StreamBuilder(
      stream: db.getDocumentsStream(collectionName: "users"),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            Map<String, dynamic> data =
                documents[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: Text("${data['age']}"),
            );
          },
        );
      },
    ),
````


sample model
````dart
class User {
  final String id;
  final String name;
  final int age;
  final String imageURL;

  User({required this.id, required this.name, required this.age, required this.imageURL});

  //the fromMap method must have id
  factory User.fromMap(String id, Map<String, dynamic> map) {
    return User(
      id: id,
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      imageURL: map['imageURL'] ?? '',
    );
  }
  
}
````

to retrieve all the documents as a List of Models

````dart
StreamBuilder(
        stream: db.getDocumentsAsModelsStream<User>(
          collectionName: 'users',
          fromMap: (documentId, data) => User.fromMap(documentId, data),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<User> users = snapshot.data ?? [];

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              User user = users[index];

              return ListTile(
                title: Text('Name: ${user.name}'),
                subtitle: Text('Age: ${user.age}'),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserDetailPage(docid: user.id),
                      ));
                },
              );
            },
          );
        },
      ),
````

### Read Document

to retrieve a document as a model

````dart
StreamBuilder(
        stream: db.getDocumentAsModelStream(
            collectionName: "users", documentId: docid, fromMap: User.fromMap),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          User? user = snapshot.data;

          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return ListTile(
            title: Text("Name: ${user.name}"),
            subtitle: Text("Age: ${user.age}"),
          );
        },
      ),
````

To retrieve documents from a Firestore collection based on a condition:

````dart
StreamBuilder(
        stream: db.getDocStreamWhere(
          collectionName: "users",
          field: "age",
          isEqualTo: 25, // Replace with the desired condition
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          List<DocumentSnapshot> documents = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data =
                  documents[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name']),
                subtitle: Text("${data['age']}"),
              );
            },
          );
        },
      ),
````
### update Document

to update a document based on document id

````dart
// Sample code for updating a document
await db.updateDocument(
  collectionName: 'users',
  documentId: 'documentId123',
  data: {'age': 26},
);
````

to update documents based on a condition

````dart
await updateWhere(
      collectionName: 'your_collection_name',
      field: 'your_field',
      isEqualTo: 'your_value',
      dataToUpdate: {'fieldToUpdate': 'new_value'},
    );
````

### Delete Document

to delete a document based on document id

````dart
// Sample code for deleting a document
await db.deleteDocument(
  collectionName: 'users',
  documentId: 'documentId123',
);
````

to delete documents based on a condition

````dart
await deleteWhere(
      collectionName: 'your_collection_name',
      field: 'your_field',
      isEqualTo: 'your_value',
    );
````
## Firebase Auth

### Register

to register using email and password

````dart
await db.register(email, password);
````

### Login

to login using email and password

````dart
await db.login(email, password);
````

### Signout

to signout from the firebase auth

````dart
await db.signOut();
````

## Firebase Storage

### Upload Image

to Upload an image to firebase storage

````dart
import 'dart:io';
import 'package:crud/db.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UploadImageToFirebase extends StatefulWidget {
  const UploadImageToFirebase({super.key});

  @override
  State<UploadImageToFirebase> createState() => _UploadImageToFirebaseState();
}

class _UploadImageToFirebaseState extends State<UploadImageToFirebase> {
  XFile? selectedImage;
  Db db = Db();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image"),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selectedImage != null) Image.file(File(selectedImage!.path)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _pickImage();
                },
                child: const Text('Pick Image'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () async {
                    String url = await db.uploadImage(
                        file: selectedImage!,
                        folderName: "Images",
                        fileName: "Image Name");
                  },
                  child: const Text('Upload Image To Firebase Storage')),
            ],
          ),
        ),
      ),
    );
  }

// Method to pick image in flutter
  Future<void> _pickImage() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }
}
````

### Upload Image in Web

to upload an image when building a website

refrence: https://flutterappcode.com/flutter-web-how-to-upload-image-to-firebase/

````dart
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UploadImageToFirebase extends StatefulWidget {
  const UploadImageToFirebase({super.key});

  @override
  State<UploadImageToFirebase> createState() => _UploadImageToFirebaseState();
}

class _UploadImageToFirebaseState extends State<UploadImageToFirebase> {
  String _imageFile = ''; // Variable to hold the selected image file
  Uint8List? selectedImageInBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Image"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageFile.isNotEmpty || _imageFile != '')
              Image.memory(selectedImageInBytes!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Calling pickImage Method
                pickImage();
              },
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: () async {
                  // Calling uploadImage Method
                  await uploadImage(selectedImageInBytes!);
                },
                child: const Text('Upload Image To Firebase Storage')),
          ],
        ),
      ),
    );
  }

  // Method to pick image in flutter web
  Future<void> pickImage() async {
    try {
      // Pick image using file_picker package
      FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      // If user picks an image, save selected image to variable
      if (fileResult != null) {
        setState(() {
          _imageFile = fileResult.files.first.name;
          selectedImageInBytes = fileResult.files.first.bytes;
        });
      }
    } catch (e) {
      // If an error occured, show SnackBar with error message
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error:$e")));
    }
  }
}
````