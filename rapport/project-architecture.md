# Project Architecture
![project architecture](/a/raw/b/project-architecture.png)

## Détails
Le produit du travail effectué par l'équipe de développement consistera en une application iOS. L'application consistera dans l'intégration de plusieurs interface de programmation d'application dans une même application.

Les différentes interfaces adressent une variété d'enjeu et intègre une variété de technologies produite non seulement par Apple. L'interface de réalité augmentée récemment dévelopée par Apple, ARKit. Celle-ci a pour principale tâche d'intégrer des fonctionnalité de la caméra de la plateforme et les fonctionnalité de détection de mouvement afin de créer une expérience de réalité augmentée.[^1]

Cette API est utilisée en coopération avec le SceneKit l'interface de gestion d'environnement 3D dans iOS aussi produit par Apple. Celle-ci simplifie les principaux défis du développement 3D comme les animations, la simulation physique, les effets de particules et le rendu réaliste avec gestion d'effet de lumière. L'usage d'une interface produite par le propriétaire de l'appareil hôte de l'application permet de s'assurer d'une optimisation fournie.[^2]

Les modèles utilisés par les Scène proviennent de modèle 3D importé par l'interface de Model I/O, il sont par la suite converti en ScnNode. Le modèle permet la gestion des textures, des assets, des caméras et des matériaux.[^3] Ce genre de modèle n'est pas propriétaire à Apple, il peut donc être utilisé par Unity[^4] et Blender[^5].

L'import des modèles 3D se fait à l'aide du senseur Structure qui est une des principal technologie du projet. Ce périphérique utilise la caméra de la tablette et la caméra sur le périphérique pour avoir une meilleur compréhension de l'environnement 3D. Le périphérique contient aussi un senseur infrarouge pour faciliter l'interprétation de l'environnement. Un kit de développement logiciel est fourni par les développeur du périphérique permettant le contrôle du senseur et l'export en modèle.[^6] Les images capturer par le senseur et la caméra sont par la suite présenté par l'interface de programmation AVKit. La classe AVCaptureDevice est ainsi utilisé pour présenté à l'usager l'environnement pris par l'appareil.[^7] Afin d'offrir un rendu plus réaliste, la librairie OpenGL est aussi utilisé.[^8]

Les liens entre la logique de notre application et celle des API se fait par des extensions au contrôleurs des vues principales de notre application et par l'intégration de certaines interfaces. Les interfaces de Structure, OpenGL, AVCaptureDevice se font par l'extension du contrôleur de vue du scanneur. Pour ce qui est du ARKit et SceneKit, les "delegates" pour chacun ont été implémenté dans le contrôleur de la vue de manipulation de modèle.

Chacun des contrôleurs est lié à une vue dans le storyboard et par les liens créer par la logique ou par ceux créer dans le storyboard, ce qui permet à l'usager de transférer d'une à l'autre.

[^1]:https://developer.apple.com/documentation/arkit/

[^2]:https://developer.apple.com/documentation/scenekit/

[^3]:https://developer.apple.com/documentation/modelio/

[^4]:https://docs.unity3d.com/540/Documentation/Manual/HOWTO-importObject.html

[^5]:https://blenderartists.org/forum/showthread.php?281322-Importing-obj-files-to-blender-2-6

[^6]:https://structure.io/developers

[^7]:https://developer.apple.com/documentation/avkit

[^8]:https://developer.apple.com/documentation/opengles
