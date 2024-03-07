
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class PhoneLoginProvider extends ChangeNotifier {

  bool _isLoading = false; //To display the circular progress indicator when completing a particular function
  bool get isLoading => _isLoading;

  Future<bool> checkIfUserExistsFirestore(String phoneNo) async
  {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('userInfo')
          .where('phoneNo',
          isEqualTo: phoneNo) //snapshot where that phoneNo exists in the userBase
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }
      return true;
    }
    catch (e) {
      rethrow;
    }
  }


  Future<void> writeUserInfo(String phoneNo, String uid) async
  {
    try {
      final docSnapshot = FirebaseFirestore.instance.collection('userInfo').doc(
          uid);
      docSnapshot.set(
          {'phoneNo': phoneNo, 'uid': uid, 'provider': "PHONE"});
    }
    catch (e) {
      Center(child: Text("$e")); //display the error;
    }
  }


  Future<String> sendOTP(String phoneNo) async {

    _isLoading = true;
    notifyListeners();

    Completer<String> completer = Completer<String>();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(

          phoneNumber: '+1$phoneNo',

          verificationCompleted: (
              PhoneAuthCredential credential) async { //if verification is completed, sign in
            await FirebaseAuth.instance.signInWithCredential(credential);
          },

          verificationFailed: (FirebaseAuthException e) async {
            throw Exception(e.message);
          },

          codeSent: (String verificationId, int? resendToken) async {
            // PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
            completer.complete(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {}
      );

      _isLoading = false;
      notifyListeners();
      return completer.future; //return the verification ID
    }
    catch (e) {
      rethrow;
    }
  }

  //function to check the OTP
  Future<bool> checkOTP(String verificationID, String otpNo) async {

    _isLoading = true;
    notifyListeners();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationID, smsCode: otpNo); //get the credentials from the verificationID of the sent text and the entered OTP
      User? user = (await FirebaseAuth.instance.signInWithCredential(credential)).user!; //sign in the user with credential

      if (!await checkIfUserExistsFirestore(user.phoneNumber!)) {
        writeUserInfo(user.phoneNumber!,
            user.uid); //write the userInfo if does not exist in firestore.
      }

      _isLoading = false; //Marking thew loading true because at this point the OTP number should be verified.
      notifyListeners();
      return true; //return true since the OTP matched
    }

    catch (e) {
      return false; //any errors caught, just return false for safety
    }
  }

  Future deletePhoneRelatedAccount() async
  {
    try{
      FirebaseFirestore.instance.collection('userInfo').doc(FirebaseAuth.instance.currentUser!.uid).delete();
      FirebaseAuth.instance.currentUser!.delete();
    }
    catch(e)
    {
      e.toString();
    }
  }
}
