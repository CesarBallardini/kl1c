# README

Se desea escribir programas en KLIC, la versión compilable en sistemas Unix de KL1

El proyecto detrás de KL1 es ICOT, que está cerrado.  Hubo un paquete Debian hasta 2006, cuyos binarios eran para 32 bits.

A los fines de recrear el paquete en una distro más moderna, he usado Ubuntu 16.04 Trusty i686.

# Cómo usar los paquetes ya preparados

En el directorio `trusty` están los paquetes `.deb` construídos para Trusty.  

```bash

# creamos la VM
vagrant up
vagrant reload

# instalamos los paquetes
vagrant ssh  #  ingresamos a la VM

cd /vagrant/trusty/
sudo dpkg -i klic_3.003-gm1-4.1_i386.deb  klic-doc_3.003-gm1-4.1_all.deb
```

# Cómo recrear los paquetes `.deb`

```bash

# creamos la VM
vagrant up
vagrant reload

# crear los paquetes
vagrant provision --provision-with crea_paquete_deb

```

Los paquetes quedan en el directorio  `/home/vagrant/deb/` (eso es dentro de la VM)




# Apéndice: Descargar fuentes klic

* descargamos una réplica del software libre de ICOT (ifs: ICOT Free Software) desde su DVD online; desde 2005 hasta al menos octubre de 2020. Ocupa unos 122 MB con más software que solamente klic.

```bash
wget --tries=inf --timestamping --recursive --level=inf --convert-links --page-requisites --no-parent -R '\?C=' https://www.ueda.info.waseda.ac.jp/AITEC_ICOT_ARCHIVES/ICOT/ifs/
popd

# También puede ser interesante replicar TODO el ICOT, aunque hay demasiado escrito en japonés, y no entiendo nada. (un par de gigabytes)
wget --tries=inf --timestamping --recursive --level=inf --convert-links --page-requisites --no-parent -R '\?C=' https://www.ueda.info.waseda.ac.jp/AITEC_ICOT_ARCHIVES/ICOT/


```

# Apéndice: Referencias

* https://www.ueda.info.waseda.ac.jp/software.html [revived!] KLIC: Portable implementation of KL1 (version 3.012) Ubuntu 18.04LTS REVISAR PARA CONTINUAR!!!


* https://en.wikipedia.org/wiki/Fifth_generation_computer Antes las generaciones tenían que ver con la electrónica: válvulas de vacío, transistores, circuitos integrados.  Ahora las generaciones tienen que ver con los lenguajes que usamos para comunicarnos con la computadora.


* https://www.sciencedirect.com/science/article/abs/pii/0167739X93900038 The Japanese national Fifth Generation project: Introduction, survey, and evaluation en: Future Generation Computer Systems Volume 9, Issue 2, July 1993, Pages 105-117
  Projecting a great vision of intelligent systems in the service of the economy and society, the Japanese government in 1982 launched the national Fifth Generation Computer Systems (FGCS) project. The project was carried out by a central research institute, ICOT, with personnel from its member-owners, the Japanese computer manufacturers (JCMs) and other electronics industry firms. The project was planned for ten years, but continues through year eleven and beyond. ICOT chose to focus its efforts on language issues and programming methods for logic programming, supported by special hardware. Sequential ‘inference machines’ (PSI) and parallel ‘inference machines’ (PIM) were built. Performances of the hardware-software hybrid was measured in the range planned (150 million logical inferences per second). An excellent system for logic programming on parallel machines was constructed (KL1). 

* El lenguaje KL1  
  * https://en.wikipedia.org/wiki/KL1
  * https://es.wikipedia.org/wiki/Kernel_Language_1 un ejemplo de programación en KL1
  * https://www.airc.aist.go.jp/aitec-icot/ICOT/Museum/IFS/abst/078.html KLIC, implementaciónde KL1 para computadoras de propósito general (no las de propósito especial del proyecto de 5ta generación japonés)


* https://www.springer.com/gp/book/9783540666837 Agent-Oriented Programming, From Prolog to Guarded Definite Clauses / Authors: Huntbach, Matthew M., Ringwood, Graem A. / 1999 / un libro que te puede volar la cabeza


* KLIC Association, ahora extinta, sus páginas en Web Archive:
  * https://web.archive.org/web/20100117145812/http://www.klic.org/software/klic/index.en.html
  * https://web.archive.org/web/20100110085645/http://www.klic.org/ no se actualizan las listas de correo desde setiembre del 2000


* https://github.com/GunterMueller/KLIC Después de hacer todo el trabajo, encontré este otro repo que al parecer ya lo tiene funcionando.  No lo miré, lo anoto para ver otro día. Mi fork en https://github.com/CesarBallardini/KLIC



