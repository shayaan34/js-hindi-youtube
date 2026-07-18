import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/app_config.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

/// Root application state: auth session, client roster, offline-sync queue.
class AppState extends ChangeNotifier {
  AppState()
      : _auth = AppConfig.useFirebase ? FirebaseAuthService() : MockAuthService(),
        _data =
            AppConfig.useFirebase ? FirestoreDataService() : InMemoryDataService();

  final AuthService _auth;
  final DataService _data;
  final _uuid = const Uuid();

  AppUser? user;
  List<Client> clients = [];

  /// Number of local changes waiting for cloud sync (offline-mode simulation
  /// in demo builds; real writes are immediate when Firebase is enabled).
  int pendingSyncCount = 0;
  bool syncing = false;

  bool get signedIn => user != null;

  // -------------------------------------------------------------- auth

  Future<void> signIn(String email, String password) async {
    user = await _auth.signIn(email, password);
    await _loadClients();
    notifyListeners();
  }

  Future<void> register(
      String name, String company, String email, String password) async {
    user = await _auth.register(name, company, email, password);
    await _loadClients();
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    user = await _auth.signInWithGoogle();
    await _loadClients();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    user = null;
    clients = [];
    notifyListeners();
  }

  // -------------------------------------------------------------- clients

  Future<void> _loadClients() async {
    clients = await _data.loadClients(user!.uid);
    if (clients.isEmpty && !AppConfig.useFirebase) {
      _seedDemoData();
    }
  }

  Client addClient({
    required String businessName,
    required String contactPerson,
    required String phone,
    required String email,
    required BusinessCategory category,
    required String address,
    String notes = '',
  }) {
    final client = Client(
      id: _uuid.v4(),
      businessName: businessName,
      contactPerson: contactPerson,
      phone: phone,
      email: email,
      category: category,
      address: address,
      notes: notes,
    );
    clients.insert(0, client);
    _persist(client);
    notifyListeners();
    return client;
  }

  void updateClient(Client client) {
    _persist(client);
    notifyListeners();
  }

  void deleteClient(Client client) {
    clients.removeWhere((c) => c.id == client.id);
    _data.deleteClient(user!.uid, client.id);
    notifyListeners();
  }

  List<Client> searchClients(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return clients;
    return clients
        .where((c) =>
            c.businessName.toLowerCase().contains(q) ||
            c.contactPerson.toLowerCase().contains(q) ||
            c.phone.contains(q) ||
            c.address.toLowerCase().contains(q) ||
            c.category.label.toLowerCase().contains(q))
        .toList();
  }

  // -------------------------------------------------------------- media

  void addPhoto(Client client, Uint8List bytes) {
    client.photos.insert(0, SitePhoto(id: _uuid.v4(), bytes: bytes));
    _data.uploadImage(
        user!.uid, 'clients/${client.id}/photos/${_uuid.v4()}.png', bytes);
    _persist(client);
    notifyListeners();
  }

  MockupProject saveMockup(Client client,
      {required String name,
      required Uint8List before,
      required Uint8List after,
      String folder = 'General'}) {
    final project = MockupProject(
      id: _uuid.v4(),
      name: name,
      folder: folder,
      beforeBytes: before,
      afterBytes: after,
    );
    client.projects.insert(0, project);
    _data.uploadImage(
        user!.uid, 'clients/${client.id}/mockups/${project.id}.png', after);
    _persist(client);
    notifyListeners();
    return project;
  }

  // -------------------------------------------------------------- sync

  void _persist(Client client) {
    pendingSyncCount++;
    notifyListeners();
    _data.saveClient(user!.uid, client).then((_) => _markSynced());
  }

  Future<void> _markSynced() async {
    // Simulate the background cloud-sync worker draining the queue.
    syncing = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    pendingSyncCount = pendingSyncCount > 0 ? pendingSyncCount - 1 : 0;
    syncing = pendingSyncCount > 0;
    notifyListeners();
  }

  // -------------------------------------------------------------- stats

  DashboardStats get stats {
    final projects =
        clients.fold<int>(0, (sum, c) => sum + c.projects.length);
    final installed =
        clients.where((c) => c.status == ProjectStatus.installed).length;
    final pendingQuotes = clients
        .where((c) =>
            c.status == ProjectStatus.quoteSent ||
            c.status == ProjectStatus.mockupSent)
        .length;
    final approved = clients
        .where((c) =>
            c.status == ProjectStatus.approved ||
            c.status == ProjectStatus.installed)
        .length;
    return DashboardStats(
      totalClients: clients.length,
      totalProjects: projects,
      revenue: approved * 86500.0,
      pendingQuotes: pendingQuotes,
      completedInstallations: installed,
    );
  }

  // -------------------------------------------------------------- demo seed

  void _seedDemoData() {
    clients = [
      Client(
        id: _uuid.v4(),
        businessName: 'Café Aroma',
        contactPerson: 'Priya Sharma',
        phone: '+91 98765 43210',
        email: 'priya@cafearoma.in',
        category: BusinessCategory.coffeeShop,
        address: '12 MG Road, Bengaluru',
        notes: 'Interested in a 43" menu board behind the counter.',
        status: ProjectStatus.mockupSent,
      ),
      Client(
        id: _uuid.v4(),
        businessName: 'Spice Route Restaurant',
        contactPerson: 'Arjun Mehta',
        phone: '+91 91234 56780',
        email: 'arjun@spiceroute.in',
        category: BusinessCategory.restaurant,
        address: '45 Linking Road, Mumbai',
        notes: 'Wants LED wall near entrance + window vinyl.',
        status: ProjectStatus.quoteSent,
      ),
      Client(
        id: _uuid.v4(),
        businessName: 'Phoenix Mall Atrium',
        contactPerson: 'Sneha Kulkarni',
        phone: '+91 99887 77665',
        email: 'sneha@phoenixmall.in',
        category: BusinessCategory.mall,
        address: 'Viman Nagar, Pune',
        notes: 'Large 75" displays for atrium pillars, phase 1 of 3.',
        status: ProjectStatus.installed,
      ),
    ];
  }
}
