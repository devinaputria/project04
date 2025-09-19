// File: review_page.dart (Enhanced with stylish UI + animations + confirmation, delete, and edit)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'student_service.dart';
import 'student_form_page.dart'; // For navigating to edit mode

class ReviewPage extends StatefulWidget {
  final Color primaryDarkBlue;
  final String nisn;
  final String name;
  final String jenisKelamin;
  final String agama;
  final String tempatTanggalLahir;
  final String noTelepon;
  final String nik;
  final Map<String, dynamic> alamat;
  final String namaAyah;
  final String namaIbu;
  final String? namaWali;
  final String alamatOrtu;
  final bool isEditMode;

  const ReviewPage({
    super.key,
    required this.primaryDarkBlue,
    required this.nisn,
    required this.name,
    required this.jenisKelamin,
    required this.agama,
    required this.tempatTanggalLahir,
    required this.noTelepon,
    required this.nik,
    required this.alamat,
    required this.namaAyah,
    required this.namaIbu,
    this.namaWali,
    required this.alamatOrtu,
    this.isEditMode = false,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  bool _isSaving = false;
  bool _isSaved = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveToSupabase() async {
    if (_isSaving) return;
    final confirm = await _confirmAction(
        widget.isEditMode ? 'Perbarui' : 'Simpan', widget.name);
    if (confirm != true || !mounted) return;

    setState(() {
      _isSaving = true;
      _isSaved = false;
    });

    final ttlParts = widget.tempatTanggalLahir.split(', ');
    final tempat = ttlParts.isNotEmpty ? ttlParts[0] : '';
    final tanggal = ttlParts.length > 1 ? ttlParts[1] : '';

    final data = {
      'nisn': widget.nisn,
      'name': widget.name,
      'jenis_kelamin': widget.jenisKelamin,
      'agama': widget.agama,
      'tempat_lahir': tempat,
      'tanggal_lahir': tanggal,
      'no_telepon': widget.noTelepon,
      'nik': widget.nik,
      'jalan': widget.alamat['jalan']?.toString() ?? '',
      'rt_rw': widget.alamat['rt_rw']?.toString() ?? '',
      'dusun': widget.alamat['dusun']?.toString() ?? '',
      'desa': widget.alamat['desa']?.toString() ?? '',
      'kecamatan': widget.alamat['kecamatan']?.toString() ?? '',
      'kabupaten': widget.alamat['kabupaten']?.toString() ?? '',
      'provinsi': widget.alamat['provinsi']?.toString() ?? '',
      'kode_pos': widget.alamat['kode_pos']?.toString() ?? '',
      'nama_ayah': widget.namaAyah,
      'nama_ibu': widget.namaIbu,
      'nama_wali': widget.namaWali ?? '',
      'alamat_orang_tua': widget.alamatOrtu,
    };

    try {
      await _studentService.saveStudent(data, isEditMode: widget.isEditMode);
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.isEditMode
            ? '✅ Data berhasil diperbarui!'
            : '✅ Data berhasil disimpan!'),
      ));

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Gagal menyimpan: $e')));
    }
  }

  Future<void> _deleteStudent() async {
    final confirm = await _confirmAction('Hapus', widget.name);
    if (confirm != true || !mounted) return;

    try {
      await _studentService.deleteStudent(widget.nisn);
      _showNotification('Data ${widget.name} dihapus', isError: false);
      Navigator.pop(context, true); // Return true to refresh HomePage
    } catch (e) {
      _showNotification('Gagal menghapus: $e', isError: true);
    }
  }

  Future<bool?> _confirmAction(String action, String name) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action Konfirmasi',
            style: TextStyle(color: widget.primaryDarkBlue, fontWeight: FontWeight.bold)),
        content: Text(
            'Apakah Anda yakin ingin $action data "$name"? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: widget.primaryDarkBlue),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya')),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
      ),
    );
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _navigateToEdit() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFormPage(
      primaryDarkBlue: widget.primaryDarkBlue,
      existingData: {
        'nisn': widget.nisn,
        'name': widget.name,
        'jenis_kelamin': widget.jenisKelamin,
        'agama': widget.agama,
        'tempat_lahir': widget.tempatTanggalLahir.split(', ')[0],
        'tanggal_lahir': widget.tempatTanggalLahir.split(', ')[1],
        'no_telepon': widget.noTelepon,
        'nik': widget.nik,
        'jalan': widget.alamat['jalan'],
        'rt_rw': widget.alamat['rt_rw'],
        'dusun': widget.alamat['dusun'],
        'desa': widget.alamat['desa'],
        'kecamatan': widget.alamat['kecamatan'],
        'kabupaten': widget.alamat['kabupaten'],
        'provinsi': widget.alamat['provinsi'],
        'kode_pos': widget.alamat['kode_pos'],
        'nama_ayah': widget.namaAyah,
        'nama_ibu': widget.namaIbu,
        'nama_wali': widget.namaWali,
        'alamat_orang_tua': widget.alamatOrtu,
      },
    )));
    if (result == true) {
      Navigator.pop(context, true); // Refresh HomePage
    }
  }

  Widget _buildCard(String title, IconData icon, List<Widget> children) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.primaryDarkBlue, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowText(String label, String? value) {
    final display = (value == null || value.isEmpty) ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: TextStyle(
                      color: widget.primaryDarkBlue,
                      fontWeight: FontWeight.w600))),
          Expanded(
              flex: 5,
              child: Text(display,
                  style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alamat = widget.alamat;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: widget.primaryDarkBlue,
        title: Text(widget.isEditMode
            ? 'Edit Data Siswa'
            : 'Review Data Siswa'),
        elevation: 6,
        actions: widget.isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: _navigateToEdit,
                  tooltip: 'Edit Data',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteStudent,
                  tooltip: 'Hapus Data',
                ),
              ]
            : null, // Tidak ada actions jika bukan edit mode
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCard('Data Siswa', Icons.person, [
                _rowText('NISN', widget.nisn),
                _rowText('Nama', widget.name),
                _rowText('Jenis Kelamin', widget.jenisKelamin),
                _rowText('Agama', widget.agama),
                _rowText('TTL', widget.tempatTanggalLahir),
                _rowText('No Telepon', widget.noTelepon),
                _rowText('NIK', widget.nik),
              ]),
              _buildCard('Alamat', Icons.home, [
                _rowText('Jalan', alamat['jalan']?.toString()),
                _rowText('RT/RW', alamat['rt_rw']?.toString()),
                _rowText('Dusun', alamat['dusun']?.toString()),
                _rowText('Desa', alamat['desa']?.toString()),
                _rowText('Kecamatan', alamat['kecamatan']?.toString()),
                _rowText('Kabupaten', alamat['kabupaten']?.toString()),
                _rowText('Provinsi', alamat['provinsi']?.toString()),
                _rowText('Kode Pos', alamat['kode_pos']?.toString()),
              ]),
              _buildCard('Orang Tua / Wali', Icons.family_restroom, [
                _rowText('Nama Ayah', widget.namaAyah),
                _rowText('Nama Ibu', widget.namaIbu),
                _rowText('Nama Wali', widget.namaWali ?? '-'),
                _rowText('Alamat Ortu', widget.alamatOrtu),
              ]),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isSaving ? null : () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text("Kembali"),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveToSupabase,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.primaryDarkBlue,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : _isSaved
                            ? const Icon(Icons.check, color: Colors.white)
                            : const Icon(Icons.save),
                    label: Text(
                        _isSaving
                            ? "Menyimpan..."
                            : _isSaved
                                ? "Tersimpan"
                                : widget.isEditMode
                                    ? "Perbarui"
                                    : "Simpan",
                        style: const TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
          if (_isSaving)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
        ],
      ),
    );
  }
}