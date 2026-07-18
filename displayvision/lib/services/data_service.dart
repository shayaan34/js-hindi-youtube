import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/models.dart';

/// Persistence facade. Demo mode keeps everything in memory (with an
/// offline-sync queue simulation); Firebase mode mirrors client records to
/// Firestore and photo/mockup bytes to Firebase Storage.
abstract class DataService {
  Future<List<Client>> loadClients(String uid);
  Future<void> saveClient(String uid, Client client);
  Future<void> deleteClient(String uid, String clientId);
  Future<String?> uploadImage(String uid, String path, Uint8List bytes);
}

class InMemoryDataService implements DataService {
  final List<Client> _clients = [];

  @override
  Future<List<Client>> loadClients(String uid) async => _clients;

  @override
  Future<void> saveClient(String uid, Client client) async {
    final i = _clients.indexWhere((c) => c.id == client.id);
    if (i >= 0) {
      _clients[i] = client;
    } else {
      _clients.add(client);
    }
  }

  @override
  Future<void> deleteClient(String uid, String clientId) async {
    _clients.removeWhere((c) => c.id == clientId);
  }

  @override
  Future<String?> uploadImage(String uid, String path, Uint8List bytes) async {
    // Demo mode keeps bytes in memory only.
    return null;
  }
}

class FirestoreDataService implements DataService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseStorage get _storage => FirebaseStorage.instance;

  CollectionReference<Map<String, dynamic>> _clientsRef(String uid) =>
      _db.collection('companies').doc(uid).collection('clients');

  @override
  Future<List<Client>> loadClients(String uid) async {
    final snap = await _clientsRef(uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Client.fromMap(d.data())).toList();
  }

  @override
  Future<void> saveClient(String uid, Client client) async {
    await _clientsRef(uid)
        .doc(client.id)
        .set(client.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> deleteClient(String uid, String clientId) async {
    await _clientsRef(uid).doc(clientId).delete();
  }

  @override
  Future<String?> uploadImage(String uid, String path, Uint8List bytes) async {
    final ref = _storage.ref('companies/$uid/$path');
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    return ref.getDownloadURL();
  }
}
