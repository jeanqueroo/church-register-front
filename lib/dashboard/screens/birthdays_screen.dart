import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/models/user_profile.dart'; 

class BirthdaysScreen extends StatelessWidget {
  final UserSession session;

  const BirthdaysScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFF041E42), // Fondo oscuro
      appBar: AppBar(
        backgroundColor: const Color(0xFF041E42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF29D2F5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cumpleaños de Hoy', style: TextStyle(color: Color(0xFF29D2F5), fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<QuerySnapshot>(
            // Buscamos en la colección 'members'
            stream: FirebaseFirestore.instance
                .collection('members') 
                .where('churchId', isEqualTo: session.profile.churchId) 
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF29D2F5)));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No hay miembros registrados.', style: TextStyle(color: Colors.white70, fontSize: 18)),
                );
              }

              // Filtrar a los que cumplen años HOY
              final birthdaysToday = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                
                // Leemos el campo exacto de tu Firebase: 'birthDate'
                final birthDateTimestamp = data['birthDate']; 
                
                if (birthDateTimestamp == null) return false;
                
                DateTime? birthDate;
                if (birthDateTimestamp is Timestamp) {
                  birthDate = birthDateTimestamp.toDate();
                } else if (birthDateTimestamp is String) {
                  birthDate = DateTime.tryParse(birthDateTimestamp);
                }

                if (birthDate == null) return false;

                // Comprobar si el mes y el día coinciden con hoy
                return birthDate.month == today.month && birthDate.day == today.day;
              }).toList();

              if (birthdaysToday.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cake_outlined, color: Colors.white38, size: 60),
                      SizedBox(height: 15),
                      Text('No hay cumpleaños hoy 🎂', style: TextStyle(color: Colors.white70, fontSize: 18)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: birthdaysToday.length,
                itemBuilder: (context, index) {
                  final member = birthdaysToday[index].data() as Map<String, dynamic>;
                  
                  // 👇 AQUÍ JUNTAMOS EL NOMBRE Y EL APELLIDO 👇
                  // Busca 'lastName' o 'apellido' en tu Firebase y los une
                  String firstName = member['firstName'] ?? '';
                  String lastName = member['lastName'] ?? member['apellido'] ?? ''; 
                  
                  final nombreCompleto = '$firstName $lastName'.trim();
                  final nombre = nombreCompleto.isEmpty ? 'Sin nombre' : nombreCompleto;

                  final telefono = member['telefono'] ?? member['phone'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A3370), // Azul de las tarjetas
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Color(0xFF1A66C2), shape: BoxShape.circle),
                        child: const Icon(Icons.cake, color: Colors.white, size: 24),
                      ),
                      title: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(telefono.isNotEmpty ? '📞 $telefono' : 'Sin teléfono registrado', style: const TextStyle(color: Color(0xFFA0C1E8), fontSize: 14)),
                      ),
                      trailing: const Icon(Icons.celebration, color: Color(0xFF29D2F5), size: 28),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}