import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:universal_platform/universal_platform.dart'; // Platform check for web compatibility

class CallPage extends StatelessWidget {
  final String userID;
  final String userName;
  final String callID;
  final bool isVideoCall;

  const CallPage({
    Key? key,
    required this.userID,
    required this.userName,
    required this.callID,
    required this.isVideoCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UniversalPlatform.isWeb
        ? _buildWebCallUI(context)
        : _buildMobileCallUI(context);
  }

  Widget _buildMobileCallUI(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: 225051930, // Replace with your ZegoCloud App ID
      appSign:
          'fab20a1dce44c69f1334f4dc7d7362a4acab516f94e2f88283ca316c8d0b8dc5', // Replace with your ZegoCloud App Sign
      userID: userID,
      userName: userName,
      callID: callID,
      config: isVideoCall
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }

  Widget _buildWebCallUI(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      appID: 225051930, // Replace with your ZegoCloud App ID
      appSign:
          'fab20a1dce44c69f1334f4dc7d7362a4acab516f94e2f88283ca316c8d0b8dc5', // Replace with your ZegoCloud App Sign
      userID: userID,
      userName: userName,
      callID: callID,
      config: isVideoCall
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}
