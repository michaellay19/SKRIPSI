class Employee {
  final String uid;
  final String no;
  final String name;
  final String nik;
  final String email;
  final String? gender, dob, pob, position, religion, address, employeeStatus, joinDate, phone;

  Employee({
    required this.uid,
    required this.no,
    required this.name,
    required this.nik,
    required this.email,
    this.gender,
    this.dob,
    this.pob,
    this.position,
    this.religion,
    this.address,
    this.employeeStatus,
    this.joinDate,
    this.phone,
  });

  Employee copyWith({
    String? no,
    String? name,
    String? nik,
    String? email,
    String? gender,
    String? dob,
    String? pob,
    String? position,
    String? religion,
    String? address,
    String? employeeStatus,
    String? joinDate,
    String? phone,
  }) {
    return Employee(
      uid: uid,
      no: no ?? this.no,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      pob: pob ?? this.pob,
      position: position ?? this.position,
      religion: religion ?? this.religion,
      address: address ?? this.address,
      employeeStatus: employeeStatus ?? this.employeeStatus,
      joinDate: joinDate ?? this.joinDate,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'no': no,
      'name': name,
      'nik': nik,
      'email': email,
      'gender': gender,
      'dob': dob,
      'pob': pob,
      'position': position,
      'religion': religion,
      'address': address,
      'employeeStatus': employeeStatus,
      'joinDate': joinDate,
      'phone': phone,
    };
  }
}
