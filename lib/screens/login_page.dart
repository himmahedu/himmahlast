if (mounted) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('تم الدخول')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text('تم تسجيل الدخول بنجاح'),
              Text('البريد: ${_emailCtrl.text.trim()}'),
            ],
          ),
        ),
      ),
    ),
    (route) => false,
  );
}
