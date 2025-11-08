import 'package:flutter/material.dart';

class TelaCreditos extends StatelessWidget {
  const TelaCreditos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF111827), Color(0xFF1F2937)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                foregroundColor: Colors.white,
                title: const Text('Sobre o Projeto'),
                centerTitle: true,
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.tealAccent.withAlpha(77),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withAlpha(13),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const CircleAvatar(
                                radius: 40,
                                backgroundColor: Color(0xFF111827),
                                child: Icon(Icons.code_rounded, size: 40, color: Colors.tealAccent),
                              ),
                              
                              const SizedBox(height: 25),
                              
                              const Text('Guilherme Moreira Dias',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                              
                              const SizedBox(height: 15),
                              
                              const Text('Idealizador & Desenvolvedor Inicial',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, color: Colors.white70, fontStyle: FontStyle.italic)),
                              
                              const SizedBox(height: 25),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 25),
                              
                              Chip(
                                avatar: const Icon(Icons.school_outlined, color: Colors.tealAccent),
                                label: const Text('BSI - 1º Semestre',
                                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600)),
                                backgroundColor: Colors.tealAccent.withAlpha(26),
                                side: BorderSide(color: Colors.tealAccent.withAlpha(77)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 50),
                        
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                          label: const Text('VOLTAR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}