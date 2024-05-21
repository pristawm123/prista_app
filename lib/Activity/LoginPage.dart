import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:prista_app/Activity/DeteksiPenyakitPage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<Login> {
  login()async{

    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DeteksiPenyakitPage()),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: (()=>login()),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Sign In With Google",style: TextStyle(fontSize: 25),),
            ),
        ),
        )
    );
  }
}




// class _LoginScreenState extends State<Login> {

//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   Future<User?> _signInWithGoogle() async {
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         return null; // Jika login dibatalkan oleh pengguna
//       }

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       final UserCredential userCredential = await _auth.signInWithCredential(credential);
//       final User? user = userCredential.user;

//       return user;
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Login with Google'),
//       ),
//       body: Center(
//         child: ElevatedButton(
//           onPressed: () async {
//             User? user = await _signInWithGoogle();
//             if (user != null) {
//               // Navigasi ke halaman lain setelah login sukses
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => HomePage(user: user)),
//               );
//             }
//           },
//           child: Text('Login with Google'),
//         ),
//       ),
//     );
//   }
// }

// class HomePage extends StatelessWidget {
//   final User user;

//   HomePage({required this.user});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home'),
//       ),
//       body: Center(
//         child: Text('Welcome, ${user.displayName}!'),
//       ),
//     );
//   }
// }
