import 'package:flutter/material.dart';
import 'student_form_page.dart';
import 'student_service.dart';

class HomePage extends StatefulWidget {
  final Color primaryDarkBlue;

  const HomePage({
    super.key,
    required this.primaryDarkBlue,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StudentService studentService = StudentService();
  List<Map<String, dynamic>> students = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _testConnectionAndFetch();
  }

  Future<void> _testConnectionAndFetch() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      await studentService.testConnection();
      await _fetchStudents();
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal menghubungkan ke database: $e';
        });
      }
      print('Error koneksi: $e');
    }
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await studentService.getStudents();
      if (mounted) {
        setState(() {
          students = response;
          isLoading = false;
        });
      }
      print('Berhasil memuat siswa: $students');
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Gagal memuat data siswa: $e';
        });
      }
      print('Error memuat data: $e');
    }
  }

  Future<bool?> _showDeleteConfirmation(String name) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Penghapusan', style: TextStyle(color: widget.primaryDarkBlue)),
          content: Text('Apakah Anda yakin ingin menghapus data siswa "$name"? Tindakan ini tidak bisa dibatalkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.primaryDarkBlue,
        title: Text(
          'Daftar Siswa',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: widget.primaryDarkBlue.withOpacity(0.1),
              border: const Border(
                bottom: BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
            child: Text(
              'Daftar Siswa Terdaftar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.primaryDarkBlue,
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 18, color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.primaryDarkBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  side: const BorderSide(color: Colors.grey, width: 1.0),
                                ),
                              ),
                              onPressed: _testConnectionAndFetch,
                              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ],
                        ),
                      )
                    : students.isEmpty
                        ? Center(
                            child: Text(
                              'Belum ada data siswa',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: students.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                            itemBuilder: (context, index) {
                              final student = students[index];
                              return Dismissible(
                                key: Key(student['nisn']),
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  return await _showDeleteConfirmation(student['name'] ?? 'Siswa');
                                },
                                onDismissed: (direction) async {
                                  try {
                                    await studentService.deleteStudent(student['nisn']);
                                    setState(() {
                                      students.removeAt(index);
                                    });
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Data ${student['name']} dihapus')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal menghapus data: $e')),
                                      );
                                    }
                                    print('Error menghapus: $e');
                                    await _fetchStudents();
                                  }
                                },
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                    side: BorderSide(color: Colors.grey[300]!, width: 1.0),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.white,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: widget.primaryDarkBlue.withOpacity(0.1),
                                      child: Icon(Icons.person, color: widget.primaryDarkBlue, size: 20),
                                    ),
                                    title: Text(
                                      student['name'] ?? 'Nama Tidak Diketahui',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('NISN: ${student['nisn'] ?? 'Tidak Diketahui'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                        Text('Desa: ${student['desa'] ?? 'Tidak Diketahui'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                        Text('Kabupaten: ${student['kabupaten'] ?? 'Tidak Diketahui'}', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                      ],
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[600]),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StudentFormPage(
                                            primaryDarkBlue: widget.primaryDarkBlue,
                                            existingData: student,
                                          ),
                                        ),
                                      );
                                      if (result == true) {
                                        await _fetchStudents();
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.primaryDarkBlue,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentFormPage(primaryDarkBlue: widget.primaryDarkBlue),
            ),
          );
          if (result == true) {
            await _fetchStudents();
          }
        },
        tooltip: 'Tambah Data',
        child: const Icon(Icons.add, color: Colors.white, size: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: const BorderSide(color: Colors.white, width: 1.0),
        ),
        elevation: 6,
      ),
    );
  }
}