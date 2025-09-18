import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer; // For logging

// KOMENTAR: Service untuk menangani operasi terkait data siswa di Supabase
class StudentService {
  final SupabaseClient supabase;
  StudentService() : supabase = Supabase.instance.client;

  // KOMENTAR: Mengambil daftar dusun dari tabel locations untuk autocomplete
  Future<List<String>> getDusunOptions() async {
    try {
      final response = await supabase
          .from('locations')
          .select('dusun')
          .order('dusun', ascending: true);
      return response.map((e) => e['dusun'] as String).toSet().toList(); // Hapus duplikat
    } on PostgrestException catch (e) {
      developer.log('Error fetching dusun options: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memuat dusun: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching dusun options: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat dusun: $e');
    }
  }

  // KOMENTAR: Mengambil data alamat berdasarkan dusun untuk auto-fill
  Future<List<Map<String, dynamic>>> getAddressByDusun(String dusun) async {
    try {
      if (dusun.isEmpty) {
        throw Exception('Dusun tidak boleh kosong');
      }
      final response = await supabase
          .from('locations')
          .select('desa, kecamatan, kabupaten, provinsi, kode_pos')
          .eq('dusun', dusun);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      developer.log('Error fetching address for dusun $dusun: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memuat alamat: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching address: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat alamat: $e');
    }
  }

  // KOMENTAR: Memeriksa apakah NISN sudah ada di tabel students
  Future<bool> isNisnExists(String nisn) async {
    try {
      if (nisn.isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      final response = await supabase
          .from('students')
          .select('nisn')
          .eq('nisn', nisn)
          .limit(1);
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      developer.log('Error checking NISN $nisn: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memeriksa NISN: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error checking NISN: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memeriksa NISN: $e');
    }
  }

  // KOMENTAR: Memeriksa apakah dusun ada di tabel locations
  Future<bool> isDusunValid(String dusun) async {
    try {
      if (dusun.isEmpty) {
        throw Exception('Dusun tidak boleh kosong');
      }
      final response = await supabase
          .from('locations')
          .select('dusun')
          .eq('dusun', dusun)
          .limit(1);
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      developer.log('Error validating dusun $dusun: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memeriksa dusun: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error validating dusun: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memeriksa dusun: $e');
    }
  }

  // KOMENTAR: Menyimpan atau memperbarui data siswa di tabel students
  Future<void> saveStudent(Map<String, dynamic> data, {bool isEditMode = false}) async {
    try {
      // Validasi input data
      if (data['nisn'] == null || data['nisn'].isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      if (data['dusun'] != null && data['dusun'].isNotEmpty) {
        final validDusun = await isDusunValid(data['dusun']);
        if (!validDusun) {
          throw Exception('Dusun ${data['dusun']} tidak ditemukan di tabel locations');
        }
      }
      // Validasi NISN unik untuk insert baru
      if (!isEditMode) {
        final nisnExists = await isNisnExists(data['nisn']);
        if (nisnExists) {
          throw Exception('NISN ${data['nisn']} sudah terdaftar');
        }
      }
      if (isEditMode) {
        await supabase
            .from('students')
            .update(data)
            .eq('nisn', data['nisn']);
      } else {
        await supabase
            .from('students')
            .insert(data);
      }
    } on PostgrestException catch (e) {
      developer.log('Error saving student data: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menyimpan data: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error saving student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menyimpan data: $e');
    }
  }

  // KOMENTAR: Menambahkan data siswa baru
  Future<void> addStudent(Map<String, dynamic> data) async {
    try {
      // Validasi input data
      if (data['nisn'] == null || data['nisn'].isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      final nisnExists = await isNisnExists(data['nisn']);
      if (nisnExists) {
        throw Exception('NISN ${data['nisn']} sudah terdaftar');
      }
      await supabase.from('students').insert(data);
    } on PostgrestException catch (e) {
      developer.log('Error adding student: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menambah data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error adding student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menambah data siswa: $e');
    }
  }

  // KOMENTAR: Memperbarui data siswa berdasarkan ID
  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      if (data.isEmpty) {
        throw Exception('Data untuk pembaruan tidak boleh kosong');
      }
      await supabase.from('students').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      developer.log('Error updating student ID $id: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memperbarui data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error updating student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memperbarui data siswa: $e');
    }
  }

  // KOMENTAR: Mengambil daftar semua siswa dari tabel students
  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final response = await supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      developer.log('Error fetching students: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memuat data siswa: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching students: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat data siswa: $e');
    }
  }

  // KOMENTAR: Menghapus data siswa berdasarkan NISN
  Future<void> deleteStudent(String nisn) async {
    try {
      if (nisn.isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      await supabase.from('students').delete().eq('nisn', nisn);
    } on PostgrestException catch (e) {
      developer.log('Error deleting student with NISN $nisn: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menghapus data: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error deleting student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menghapus data: $e');
    }
  }

  // KOMENTAR: Menguji koneksi ke tabel students
  Future<void> testConnection() async {
    try {
      final response = await supabase.from('students').select('id').limit(1);
      developer.log('Test connection successful: $response', name: 'StudentService');
    } on PostgrestException catch (e) {
      developer.log('Error testing connection: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menguji koneksi: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error testing connection: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menguji koneksi: $e');
    }
  }
}