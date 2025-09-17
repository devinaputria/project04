import 'package:flutter/material.dart';
import 'student_service.dart';

// KOMENTAR: Widget untuk halaman review data siswa sebelum disimpan / diperbarui
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

class _ReviewPageState extends State<ReviewPage> {
  final StudentService _studentService = StudentService();
  bool _isSaving = false;

  Future<void> _saveToSupabase() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    // Amankan split agar tidak error index out of range
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditMode ? 'Data berhasil diperbarui!' : 'Data berhasil disimpan!'),
        ),
      );

      // Kembalikan data ke screen sebelumnya
      if (!mounted) return;
      Navigator.pop(context, data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
      );
      print('ReviewPage.save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _rowText(String label, String? value) {
    final display = (value == null || value.isEmpty) ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $display'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alamat = widget.alamat;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryDarkBlue,
        title: Text(widget.isEditMode ? 'Edit Data Siswa' : 'Review Data Siswa'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text('Data Siswa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _rowText('NISN', widget.nisn),
                _rowText('Nama', widget.name),
                _rowText('Jenis Kelamin', widget.jenisKelamin),
                _rowText('Agama', widget.agama),
                _rowText('Tempat, Tanggal Lahir', widget.tempatTanggalLahir),
                _rowText('No Telepon', widget.noTelepon),
                _rowText('NIK', widget.nik),
                const SizedBox(height: 20),
                const Text('Alamat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _rowText('Jalan', alamat['jalan']?.toString() ?? '-'),
                _rowText('RT/RW', alamat['rt_rw']?.toString() ?? '-'),
                _rowText('Dusun', alamat['dusun']?.toString() ?? '-'),
                _rowText('Desa', alamat['desa']?.toString() ?? '-'),
                _rowText('Kecamatan', alamat['kecamatan']?.toString() ?? '-'),
                _rowText('Kabupaten', alamat['kabupaten']?.toString() ?? '-'),
                _rowText('Provinsi', alamat['provinsi']?.toString() ?? '-'),
                _rowText('Kode Pos', alamat['kode_pos']?.toString() ?? '-'),
                const SizedBox(height: 20),
                const Text('Orang Tua / Wali', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _rowText('Nama Ayah', widget.namaAyah),
                _rowText('Nama Ibu', widget.namaIbu),
                _rowText('Nama Wali', widget.namaWali ?? '-'),
                _rowText('Alamat Orang Tua/Wali', widget.alamatOrtu.isEmpty ? '-' : widget.alamatOrtu),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('Kembali'),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveToSupabase,
                      style: ElevatedButton.styleFrom(backgroundColor: widget.primaryDarkBlue),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(widget.isEditMode ? 'Perbarui' : 'Simpan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isSaving)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}