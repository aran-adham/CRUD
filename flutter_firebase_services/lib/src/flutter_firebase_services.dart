// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class Db {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  //function to add a document
  Future<void> addDocument(
      {required String collectionName,
      required Map<String, dynamic> data}) async {
    await _fs.collection(collectionName).add(data);
    debugPrint("Data added to Firestore");
  }

  //function to get a document based on a condition
  Stream<QuerySnapshot> getDocStreamWhere(
      {required String collectionName,
      required String field,
      required dynamic isEqualTo}) {
    Query querySnapshot = _fs.collection(collectionName);

    querySnapshot = querySnapshot.where(field, isEqualTo: isEqualTo);

    return querySnapshot.snapshots();
  }

  //function to get all the documents in a collection
  Stream<QuerySnapshot>? getDocumentsStream({required String collectionName}) {
    Stream<QuerySnapshot> querySnapshot =
        _fs.collection(collectionName).snapshots();
    return querySnapshot;
  }

  //Generic function to retrieve all the documents as a List of Models
  Stream<List<T>> getDocumentsAsModelsStream<T>({
    required String collectionName,
    required T Function(String, Map<String, dynamic>) fromMap,
  }) {
    return _fs
        .collection(collectionName)
        .snapshots()
        .map((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.map((doc) {
        String documentId = doc.id;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return fromMap(documentId, data);
      }).toList();
    });
  }

  // Generic function to retrieve a document as a model
  Stream<T?> getDocumentAsModelStream<T>({
    required String collectionName,
    required String documentId,
    required T Function(String, Map<String, dynamic>) fromMap,
  }) {
    return _fs
        .collection(collectionName)
        .doc(documentId)
        .snapshots()
        .map((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        String documentId = documentSnapshot.id;
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        return fromMap(documentId, data);
      } else {
        return null;
      }
    });
  }

  //function to update a document based on document id
  Future<void> updateDocument(
      {required String collectionName,
      required String documentId,
      required Map<String, dynamic> data}) async {
    await _fs.collection(collectionName).doc(documentId).update(data);
    debugPrint("Document Updated");
  }

  //function to delete a document based on document id
  Future<void> deleteDocument(
      {required String collectionName, required String documentId}) async {
    await _fs.collection(collectionName).doc(documentId).delete();

    debugPrint("Document Deleted");
  }

  // Function to update documents based on a condition
Future<void> updateWhere({
  required String collectionName,
  required String field,
  required dynamic isEqualTo,
  required Map<String, dynamic> dataToUpdate,
}) async {
  try {
    QuerySnapshot querySnapshot = await _fs
        .collection(collectionName)
        .where(field, isEqualTo: isEqualTo)
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.update(dataToUpdate);
    }
  } catch (e) {
    debugPrint("unable to update Document $e");
  }
}

// Function to delete documents based on a condition
Future<void> deleteWhere({
  required String collectionName,
  required String field,
  required dynamic isEqualTo,
}) async {
  try {
    QuerySnapshot querySnapshot = await _fs
        .collection(collectionName)
        .where(field, isEqualTo: isEqualTo)
        .get();

    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }

    debugPrint("Document deleted");
  } catch (e) {
    debugPrint("unable to delete document $e");
  }
}


  //function to register using email and password
  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      debugPrint('Registration Successfull');
    } on FirebaseAuthException catch (e) {
      debugPrint('Registration failed: $e');
    }
  }

  //function to login using email and password
  Future<void> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('Login Successfull');
    } on FirebaseAuthException catch (e) {
      debugPrint('Login failed: $e');
    }
  }

  //function to signout from the firebase auth
  Future<void> signOut() async {
    await _auth.signOut();
  }

  //function to Upload an image to firebase storage using mobile app
  Future<String> uploadImage({
    required XFile file,
    required String folderName,
    required String fileName,
  }) async {
    try {
      File imageFile = File(file.path);
      Uint8List fileData = await imageFile.readAsBytes();

      Reference referenceRoot = _storage.ref();
      Reference referenceDir = referenceRoot.child(folderName);
      Reference referenceImageToUpload = referenceDir.child(fileName);
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // UploadTask to finally upload image
      UploadTask uploadTask =
          referenceImageToUpload.putData(fileData, metadata);
      String downloadUrl = await referenceImageToUpload.getDownloadURL();

      // After successfully upload show SnackBar
      await uploadTask.whenComplete(() => debugPrint("Image Uploaded"));

      return downloadUrl;
    } catch (e) {
      // If an error occured while uploading, show error message
      debugPrint("Error uploading image: $e");
    }
    return '';
  }

  //function to Upload an image to firebase storage using website
  Future<String> uploadImageWeb(
      Uint8List selectedImageInBytes,
      String folderName,
      String filename) async {
    try {
      // This is referance where image uploaded in firebase storage bucket
      Reference ref = _storage.ref().child(folderName);

      Reference referenceImageToUpload = ref.child(filename);

      // metadata to save image extension
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // UploadTask to finally upload image
      UploadTask uploadTask =
          referenceImageToUpload.putData(selectedImageInBytes, metadata);

      // After successfully upload show SnackBar
      await uploadTask.whenComplete(() => debugPrint("Image Uploaded"));
      return await referenceImageToUpload.getDownloadURL();
    } catch (e) {
      // If an error occured while uploading, show error message
      debugPrint("Error uploading image: $e");
    }
    return '';
  }
}
