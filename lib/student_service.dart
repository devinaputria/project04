// File: student_service.dart
// Service untuk CRUD ke Supabase dengan error handling koneksi internet dan Supabase.
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';

class StudentService {
  final SupabaseClient supabase;
  StudentService() : supabase = Supabase.instance.client;

  /// 🔹 Public method untuk cek koneksi internet
  Future<bool> checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      developer.log('Error checking internet connection: $e', name: 'StudentService');
      return false;
    }
  }

  Future<List<String>> getDusunOptions() async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      final response = await supabase
          .from('locations')
          .select('dusun')
          .order('dusun', ascending: true);
      return response.map((e) => e['dusun'] as String).toSet().toList();
    } on PostgrestException catch (e) {
      developer.log('Supabase error fetching dusun options: ${e.message}', name: 'StudentService');
      throw Exception('Terjadi kesalan pada supabase anda cek internet anda ');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching dusun options: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat dusun: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAddressByDusun(String dusun) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      if (dusun.isEmpty) {
        throw Exception('Dusun tidak boleh kosong');
      }
      final response = await supabase
          .from('locations')
          .select('desa, kecamatan, kabupaten, provinsi, kode_pos')
          .eq('dusun', dusun);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      developer.log('Supabase error fetching address for dusun $dusun: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memuat alamat dari Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching address: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat alamat: $e');
    }
  }

  Future<bool> isNisnExists(String nisn) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
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
      developer.log('Supabase error checking NISN $nisn: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memeriksa NISN di Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error checking NISN: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memeriksa NISN: $e');
    }
  }

  Future<bool> isDusunValid(String dusun) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
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
      developer.log('Supabase error validating dusun $dusun: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memeriksa dusun di Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error validating dusun: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memeriksa dusun: $e');
    }
  }

  Future<void> saveStudent(Map<String, dynamic> data, {bool isEditMode = false}) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      if (data['nisn'] == null || data['nisn'].isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      if (data['dusun'] != null && data['dusun'].isNotEmpty) {
        final validDusun = await isDusunValid(data['dusun']);
        if (!validDusun) {
          throw Exception('Dusun ${data['dusun']} tidak ditemukan di tabel locations');
        }
      }
      if (!isEditMode) {
        final nisnExists = await isNisnExists(data['nisn']);
        if (nisnExists) {
          throw Exception('NISN ${data['nisn']} sudah terdaftar');
        }
      }
      if (isEditMode) {
        await supabase.from('students').update(data).eq('nisn', data['nisn']);
      } else {
        await supabase.from('students').insert(data);
      }
    } on PostgrestException catch (e) {
      developer.log('Supabase error saving student data: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menyimpan data ke Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error saving student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menyimpan data: $e');
    }
  }

  Future<void> addStudent(Map<String, dynamic> data) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      if (data['nisn'] == null || data['nisn'].isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      final nisnExists = await isNisnExists(data['nisn']);
      if (nisnExists) {
        throw Exception('NISN ${data['nisn']} sudah terdaftar');
      }
      await supabase.from('students').insert(data);
    } on PostgrestException catch (e) {
      developer.log('Supabase error adding student: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menambah data siswa ke Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error adding student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menambah data siswa: $e');
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      if (data.isEmpty) {
        throw Exception('Data untuk pembaruan tidak boleh kosong');
      }
      await supabase.from('students').update(data).eq('id', id);
    } on PostgrestException catch (e) {
      developer.log('Supabase error updating student ID $id: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memperbarui data siswa di Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error updating student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memperbarui data siswa: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      final response = await supabase
          .from('students')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      developer.log('Supabase error fetching students: ${e.message}', name: 'StudentService');
      throw Exception('Gagal memuat data siswa dari Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error fetching students: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error memuat data siswa: $e');
    }
  }

  Future<void> deleteStudent(String nisn) async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      if (nisn.isEmpty) {
        throw Exception('NISN tidak boleh kosong');
      }
      await supabase.from('students').delete().eq('nisn', nisn);
    } on PostgrestException catch (e) {
      developer.log('Supabase error deleting student with NISN $nisn: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menghapus data dari Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error deleting student: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menghapus data: $e');
    }
  }

  Future<void> testConnection() async {
    try {
      if (!await checkInternetConnection()) {
        throw Exception('Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
      }
      final response = await supabase.from('students').select('id').limit(1);
      developer.log('Test connection successful: $response', name: 'StudentService');
    } on PostgrestException catch (e) {
      developer.log('Supabase error testing connection: ${e.message}', name: 'StudentService');
      throw Exception('Gagal menguji koneksi ke Supabase: ${e.message} (Code: ${e.code}, Details: ${e.details ?? 'N/A'})');
    } catch (e, stackTrace) {
      developer.log('Unexpected error testing connection: $e', name: 'StudentService', error: e, stackTrace: stackTrace);
      throw Exception('Error menguji koneksi: $e');
    }
  }
}
