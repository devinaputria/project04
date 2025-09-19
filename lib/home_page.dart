// File: home_page.dart (Optimized layout, enhanced with dynamic animation, floating notification, and advanced UI)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'review_page.dart';
import 'student_service.dart';
import 'student_form_page.dart';

class HomePage extends StatefulWidget {
  final Color primaryDarkBlue;
  const HomePage({super.key, required this.primaryDarkBlue});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final StudentService studentService = StudentService();
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> filteredStudents = [];
  bool isLoading = false;
  String? errorMessage;
  String? notificationMessage;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;
  late AnimationController _particleController;
  late Animation<double> _particleAnimation;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _shimmerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.linear))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _shimmerController.reverse();
        else if (status == AnimationStatus.dismissed) _shimmerController.forward();
      });
    _shimmerController.forward();

    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
    _particleAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(CurvedAnimation(parent: _particleController, curve: Curves.linear));
    _testConnectionAndFetch();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _testConnectionAndFetch() async {
    setState(() => isLoading = true);
    try {
     final isConnected = await studentService.checkInternetConnection();
      if (!isConnected) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      await studentService.testConnection();
      await _fetchStudents();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString().contains('Tidak ada koneksi internet')
              ? 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.'
              : 'Gagal memuat data: kamu ini tidak ada internet tolong coba lagiii ';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _testConnectionAndFetch,
            ),
          ),
        );
      }
      print('Error koneksi: $e');
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await studentService.getStudents();
      if (mounted) {
        setState(() {
          students = response ?? [];
          filteredStudents = List.from(students);
          isLoading = false;
        });
      }
      print('Berhasil memuat siswa: $students');
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString().contains('Tidak ada koneksi internet')
              ? 'Tidak ada koneksi internet. Silakan periksa jaringan Anda.'
              : 'Gagal memuat data: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _fetchStudents,
            ),
          ),
        );
      }
      print('Error memuat data: $e');
    }
  }

  void _filterStudents(String query) {
    setState(() {
      filteredStudents = students.where((student) {
        final name = student['name']?.toString().toLowerCase() ?? '';
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showNotification(String message, {bool isError = false}) {
    setState(() => notificationMessage = message);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => notificationMessage = null);
    });
  }

  Future<bool?> _showDeleteConfirmation(String name) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Penghapusan', style: TextStyle(color: widget.primaryDarkBlue, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus "$name"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: widget.primaryDarkBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
    );
  }

  Future<void> _deleteStudent(String nisn, String name, int index) async {
    final confirm = await _showDeleteConfirmation(name);
    if (confirm == true && mounted) {
      try {
        final isConnected = await studentService.checkInternetConnection();
        if (!isConnected) {
          throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
        }
        await studentService.deleteStudent(nisn);
        setState(() => students.removeAt(index));
        _showNotification('Data $name dihapus', isError: false);
      } catch (e) {
        _showNotification('Gagal menghapus: $e', isError: true);
        await _fetchStudents();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Daftar Siswa', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, offset: const Offset(2, 2), blurRadius: 4)])),
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.primaryDarkBlue, Colors.blue[800]!], begin: Alignment.topLeft, end: Alignment.bottomRight))),
      ),
      body: Stack(
        children: [
          CustomPaint(
            painter: ParticlePainter(_particleAnimation, widget.primaryDarkBlue),
            child: Container(),
          ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(color: widget.primaryDarkBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 2))]),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterStudents,
                      decoration: InputDecoration(hintText: 'Cari siswa...', prefixIcon: Icon(Icons.search, color: widget.primaryDarkBlue), border: InputBorder.none, filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? Center(child: AnimatedBuilder(animation: _shimmerAnimation, builder: (_, __) => Container(width: 200, height: 200, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.grey[300]!, Colors.grey[100]!, Colors.grey[300]!], begin: Alignment.centerLeft, end: Alignment.centerRight, stops: const [0.0, 0.5, 1.0]), borderRadius: BorderRadius.circular(16)), child: Transform.translate(offset: Offset(_shimmerAnimation.value * 200, 0), child: const SizedBox(width: 200, height: 200)))))
                      : errorMessage != null
                          ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.wifi_off, color: Colors.red[700], size: 60), const SizedBox(height: 20), Text(errorMessage!, style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.w500), textAlign: TextAlign.center), const SizedBox(height: 20), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: widget.primaryDarkBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _testConnectionAndFetch, child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)))])))
                          : filteredStudents.isEmpty
                              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_outline, color: Colors.grey[500], size: 80), const SizedBox(height: 20), Text('Belum ada data siswa', style: TextStyle(fontSize: 22, color: Colors.grey[600], fontWeight: FontWeight.w500))]))
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filteredStudents.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: const Color(0xFFCCCCCC)),
                                  itemBuilder: (context, index) {
                                    final student = filteredStudents[index];
                                    return Dismissible(
                                      key: Key(student['nisn']?.toString() ?? 'default_$index'),
                                      direction: DismissDirection.endToStart,
                                      background: Container(
                                        decoration: BoxDecoration(color: Colors.red[700], borderRadius: BorderRadius.circular(16)),
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20),
                                        child: const Icon(Icons.delete, color: Colors.white, size: 24),
                                      ),
                                      confirmDismiss: (direction) => _showDeleteConfirmation(student['name'] ?? 'Siswa'),
                                      onDismissed: (direction) => _deleteStudent(student['nisn']?.toString() ?? '', student['name'] ?? 'Siswa', index),
                                      child: Hero(
                                        tag: 'student_${student['nisn'] ?? index}',
                                        child: Card(
                                          elevation: 10,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!, width: 1.0)),
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          color: Colors.white,
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.all(16),
                                            leading: CircleAvatar(backgroundColor: widget.primaryDarkBlue.withOpacity(0.2), child: Icon(Icons.person, color: widget.primaryDarkBlue, size: 24)),
                                            title: Text(student['name'] ?? 'Nama Tidak Diketahui', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text('NISN: ${student['nisn'] ?? 'Tidak Diketahui'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                              Text('Desa: ${student['desa'] ?? 'Tidak Diketahui'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                            ]),
                                            trailing: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey[600]),
                                            onTap: () async {
                                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewPage(
                                                primaryDarkBlue: widget.primaryDarkBlue,
                                                nisn: student['nisn']?.toString() ?? '',
                                                name: student['name'] ?? 'Nama Tidak Diketahui',
                                                jenisKelamin: student['jenis_kelamin'] ?? '',
                                                agama: student['agama'] ?? '',
                                                tempatTanggalLahir: '${student['tempat_lahir'] ?? ''}, ${student['tanggal_lahir'] ?? ''}',
                                                noTelepon: student['no_telepon'] ?? '',
                                                nik: student['nik'] ?? '',
                                                alamat: {
                                                  'jalan': student['jalan'] ?? '',
                                                  'rt_rw': student['rt_rw'] ?? '',
                                                  'dusun': student['dusun'] ?? '',
                                                  'desa': student['desa'] ?? '',
                                                  'kecamatan': student['kecamatan'] ?? '',
                                                  'kabupaten': student['kabupaten'] ?? '',
                                                  'provinsi': student['provinsi'] ?? '',
                                                  'kode_pos': student['kode_pos'] ?? '',
                                                },
                                                namaAyah: student['nama_ayah'] ?? '',
                                                namaIbu: student['nama_ibu'] ?? '',
                                                namaWali: student['nama_wali'] ?? '',
                                                alamatOrtu: student['alamat_orang_tua'] ?? '',
                                                isEditMode: true,
                                              )));
                                              if (result == true) await _fetchStudents();
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          ),
          if (notificationMessage != null)
            Positioned(
              top: 80,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: notificationMessage!.contains('Gagal') ? Colors.red[700] : Colors.green[700],
                  child: ListTile(
                    title: Text(notificationMessage!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    trailing: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => notificationMessage = null)),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.primaryDarkBlue,
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormPage(
            primaryDarkBlue: widget.primaryDarkBlue,
            existingData: null,
          )));
          if (result == true) {
            await _fetchStudents();
            _showNotification('Data siswa berhasil ditambahkan', isError: false);
          }
        },
        tooltip: 'Tambah Data',
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white, width: 2.0)),
        elevation: 10,
        splashColor: Colors.white.withOpacity(0.3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class ParticlePainter extends CustomPainter {
  final Animation<double> animation;
  final Color primaryDarkBlue;

  ParticlePainter(this.animation, this.primaryDarkBlue) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = primaryDarkBlue.withOpacity(0.1);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;

    for (int i = 0; i < 10; i++) {
      final angle = animation.value + (i * 2 * 3.14159 / 10);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawCircle(Offset(x, y), 5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}