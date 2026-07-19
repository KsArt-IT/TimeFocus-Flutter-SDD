import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:timefocus/shared/widgets/icon_picker/fa_icon_name.dart';
import 'package:timefocus/shared/widgets/icon_picker/icon_category.dart';

/// All available FontAwesome icons organized by categories.
abstract final class FaIconsData {
  const FaIconsData._();

  static const icons = [
    // Work
    FaIconName(
      name: 'userGear',
      faIcon: FontAwesomeIcons.userGear,
      category: IconCategory.work,
      keywords: ['settings', 'admin', 'account'],
    ),
    FaIconName(
      name: 'userPen',
      faIcon: FontAwesomeIcons.userPen,
      category: IconCategory.work,
      keywords: ['edit', 'profile', 'account'],
    ),
    FaIconName(
      name: 'briefcase',
      faIcon: FontAwesomeIcons.briefcase,
      category: IconCategory.work,
      keywords: ['job', 'business', 'office', 'work'],
    ),
    FaIconName(
      name: 'laptop',
      faIcon: FontAwesomeIcons.laptop,
      category: IconCategory.work,
      keywords: ['computer', 'work', 'office', 'code'],
    ),
    FaIconName(
      name: 'desktop',
      faIcon: FontAwesomeIcons.desktop,
      category: IconCategory.work,
      keywords: ['computer', 'work', 'office', 'monitor'],
    ),
    FaIconName(
      name: 'code',
      faIcon: FontAwesomeIcons.code,
      category: IconCategory.work,
      keywords: ['programming', 'developer', 'coding', 'software'],
    ),
    FaIconName(
      name: 'terminal',
      faIcon: FontAwesomeIcons.terminal,
      category: IconCategory.work,
      keywords: ['code', 'programming', 'console', 'developer'],
    ),
    FaIconName(
      name: 'building',
      faIcon: FontAwesomeIcons.building,
      category: IconCategory.buildings,
      keywords: ['office', 'company', 'business'],
    ),
    FaIconName(
      name: 'chart',
      faIcon: FontAwesomeIcons.chartLine,
      category: IconCategory.work,
      keywords: ['statistics', 'analytics', 'data', 'graph'],
    ),
    FaIconName(
      name: 'chartPie',
      faIcon: FontAwesomeIcons.chartPie,
      category: IconCategory.work,
      keywords: ['statistics', 'analytics', 'data', 'graph'],
    ),
    FaIconName(
      name: 'calculator',
      faIcon: FontAwesomeIcons.calculator,
      category: IconCategory.work,
      keywords: ['math', 'finance', 'accounting'],
    ),
    FaIconName(
      name: 'pen',
      faIcon: FontAwesomeIcons.pen,
      category: IconCategory.work,
      keywords: ['write', 'edit', 'note'],
    ),
    FaIconName(
      name: 'pencil',
      faIcon: FontAwesomeIcons.pencil,
      category: IconCategory.work,
      keywords: ['write', 'draw', 'edit', 'note'],
    ),
    FaIconName(
      name: 'calendar',
      faIcon: FontAwesomeIcons.calendar,
      category: IconCategory.time,
      keywords: ['schedule', 'date', 'plan', 'event'],
    ),
    FaIconName(
      name: 'calendarCheck',
      faIcon: FontAwesomeIcons.calendarCheck,
      category: IconCategory.time,
      keywords: ['schedule', 'done', 'task', 'complete'],
    ),
    FaIconName(
      name: 'clipboard',
      faIcon: FontAwesomeIcons.clipboard,
      category: IconCategory.work,
      keywords: ['note', 'list', 'task'],
    ),
    FaIconName(
      name: 'tasks',
      faIcon: FontAwesomeIcons.listCheck,
      category: IconCategory.work,
      keywords: ['todo', 'checklist', 'done'],
    ),
    FaIconName(
      name: 'file',
      faIcon: FontAwesomeIcons.file,
      category: IconCategory.work,
      keywords: ['document', 'paper'],
    ),
    FaIconName(
      name: 'folder',
      faIcon: FontAwesomeIcons.folder,
      category: IconCategory.work,
      keywords: ['directory', 'files', 'organize'],
    ),
    FaIconName(
      name: 'users',
      faIcon: FontAwesomeIcons.users,
      category: IconCategory.work,
      keywords: ['team', 'people', 'group', 'meeting'],
    ),
    FaIconName(
      name: 'handshake',
      faIcon: FontAwesomeIcons.handshake,
      category: IconCategory.work,
      keywords: ['deal', 'agreement', 'meeting', 'business'],
    ),
    FaIconName(
      name: 'lightbulb',
      faIcon: FontAwesomeIcons.lightbulb,
      category: IconCategory.work,
      keywords: ['idea', 'creative', 'think', 'innovation'],
    ),

    // Activities
    FaIconName(
      name: 'running',
      faIcon: FontAwesomeIcons.personRunning,
      category: IconCategory.activities,
      keywords: ['run', 'sport', 'exercise', 'fitness'],
    ),
    FaIconName(
      name: 'walking',
      faIcon: FontAwesomeIcons.personWalking,
      category: IconCategory.activities,
      keywords: ['walk', 'exercise', 'fitness'],
    ),
    FaIconName(
      name: 'biking',
      faIcon: FontAwesomeIcons.personBiking,
      category: IconCategory.activities,
      keywords: ['bike', 'cycling', 'sport', 'exercise'],
    ),
    FaIconName(
      name: 'swimming',
      faIcon: FontAwesomeIcons.personSwimming,
      category: IconCategory.activities,
      keywords: ['swim', 'pool', 'sport', 'water'],
    ),
    FaIconName(
      name: 'hiking',
      faIcon: FontAwesomeIcons.personHiking,
      category: IconCategory.activities,
      keywords: ['hike', 'mountain', 'outdoor', 'nature'],
    ),
    FaIconName(
      name: 'skiing',
      faIcon: FontAwesomeIcons.personSkiing,
      category: IconCategory.activities,
      keywords: ['ski', 'snow', 'winter', 'sport'],
    ),
    FaIconName(
      name: 'yoga',
      faIcon: FontAwesomeIcons.spa,
      category: IconCategory.activities,
      keywords: ['meditation', 'relax', 'wellness'],
    ),
    FaIconName(
      name: 'dumbbell',
      faIcon: FontAwesomeIcons.dumbbell,
      category: IconCategory.sportsFitness,
      keywords: ['gym', 'fitness', 'workout', 'exercise'],
    ),
    FaIconName(
      name: 'gamepad',
      faIcon: FontAwesomeIcons.gamepad,
      category: IconCategory.gaming,
      keywords: ['game', 'play', 'entertainment', 'gaming'],
    ),
    FaIconName(
      name: 'music',
      faIcon: FontAwesomeIcons.music,
      category: IconCategory.activities,
      keywords: ['song', 'audio', 'listen', 'entertainment'],
    ),
    FaIconName(
      name: 'guitar',
      faIcon: FontAwesomeIcons.guitar,
      category: IconCategory.activities,
      keywords: ['music', 'instrument', 'play'],
    ),
    FaIconName(
      name: 'palette',
      faIcon: FontAwesomeIcons.palette,
      category: IconCategory.activities,
      keywords: ['art', 'paint', 'draw', 'creative'],
    ),
    FaIconName(
      name: 'paintbrush',
      faIcon: FontAwesomeIcons.paintbrush,
      category: IconCategory.activities,
      keywords: ['art', 'paint', 'draw', 'creative'],
    ),
    FaIconName(
      name: 'camera',
      faIcon: FontAwesomeIcons.camera,
      category: IconCategory.activities,
      keywords: ['photo', 'picture', 'photography'],
    ),
    FaIconName(
      name: 'film',
      faIcon: FontAwesomeIcons.film,
      category: IconCategory.activities,
      keywords: ['movie', 'video', 'cinema', 'entertainment'],
    ),
    FaIconName(
      name: 'tv',
      faIcon: FontAwesomeIcons.tv,
      category: IconCategory.activities,
      keywords: ['television', 'watch', 'show', 'entertainment'],
    ),
    FaIconName(
      name: 'headphones',
      faIcon: FontAwesomeIcons.headphones,
      category: IconCategory.activities,
      keywords: ['music', 'audio', 'listen', 'podcast'],
    ),
    FaIconName(
      name: 'puzzle',
      faIcon: FontAwesomeIcons.puzzlePiece,
      category: IconCategory.activities,
      keywords: ['game', 'hobby', 'solve'],
    ),

    // Sports & Fitness
    FaIconName(
      name: 'futbol',
      faIcon: FontAwesomeIcons.futbol,
      category: IconCategory.sportsFitness,
      keywords: ['soccer', 'football', 'ball'],
    ),
    FaIconName(
      name: 'basketball',
      faIcon: FontAwesomeIcons.basketball,
      category: IconCategory.sportsFitness,
      keywords: ['ball', 'sport'],
    ),
    FaIconName(
      name: 'volleyball',
      faIcon: FontAwesomeIcons.volleyball,
      category: IconCategory.sportsFitness,
      keywords: ['ball', 'sport'],
    ),
    FaIconName(
      name: 'baseballBatBall',
      faIcon: FontAwesomeIcons.baseballBatBall,
      category: IconCategory.sportsFitness,
      keywords: ['baseball', 'ball', 'sport'],
    ),
    FaIconName(
      name: 'tableTennisPaddleBall',
      faIcon: FontAwesomeIcons.tableTennisPaddleBall,
      category: IconCategory.sportsFitness,
      keywords: ['pingpong', 'sport'],
    ),

    // Health
    FaIconName(
      name: 'heart',
      faIcon: FontAwesomeIcons.heart,
      category: IconCategory.health,
      keywords: ['love', 'health', 'fitness', 'cardio'],
    ),
    FaIconName(
      name: 'heartPulse',
      faIcon: FontAwesomeIcons.heartPulse,
      category: IconCategory.health,
      keywords: ['cardio', 'health', 'fitness', 'beat'],
    ),
    FaIconName(
      name: 'pills',
      faIcon: FontAwesomeIcons.pills,
      category: IconCategory.health,
      keywords: ['medicine', 'drug', 'pharmacy'],
    ),
    FaIconName(
      name: 'bath',
      faIcon: FontAwesomeIcons.bath,
      category: IconCategory.health,
      keywords: ['bathroom', 'hygiene', 'clean'],
    ),
    FaIconName(
      name: 'bookMedical',
      faIcon: FontAwesomeIcons.bookMedical,
      category: IconCategory.health,
      keywords: ['medicine', 'record', 'reference'],
    ),
    FaIconName(
      name: 'stethoscope',
      faIcon: FontAwesomeIcons.stethoscope,
      category: IconCategory.health,
      keywords: ['doctor', 'medicine', 'health'],
    ),
    FaIconName(
      name: 'hospital',
      faIcon: FontAwesomeIcons.hospital,
      category: IconCategory.health,
      keywords: ['medicine', 'doctor', 'health'],
    ),
    FaIconName(
      name: 'bed',
      faIcon: FontAwesomeIcons.bed,
      category: IconCategory.health,
      keywords: ['sleep', 'rest', 'bedroom'],
    ),
    FaIconName(
      name: 'moon',
      faIcon: FontAwesomeIcons.moon,
      category: IconCategory.health,
      keywords: ['sleep', 'night', 'rest'],
    ),
    FaIconName(
      name: 'brain',
      faIcon: FontAwesomeIcons.brain,
      category: IconCategory.health,
      keywords: ['think', 'mind', 'mental', 'psychology'],
    ),
    FaIconName(
      name: 'smoking',
      faIcon: FontAwesomeIcons.smoking,
      category: IconCategory.health,
      keywords: ['cigarette', 'habit', 'break'],
    ),
    FaIconName(
      name: 'smokingBan',
      faIcon: FontAwesomeIcons.banSmoking,
      category: IconCategory.health,
      keywords: ['quit', 'no smoking', 'health'],
    ),
    FaIconName(
      name: 'tooth',
      faIcon: FontAwesomeIcons.tooth,
      category: IconCategory.health,
      keywords: ['dental', 'dentist', 'health'],
    ),
    FaIconName(
      name: 'eye',
      faIcon: FontAwesomeIcons.eye,
      category: IconCategory.health,
      keywords: ['vision', 'see', 'sight'],
    ),
    FaIconName(
      name: 'baby',
      faIcon: FontAwesomeIcons.baby,
      category: IconCategory.health,
      keywords: ['child', 'kid', 'family'],
    ),

    // Education
    FaIconName(
      name: 'userGraduate',
      faIcon: FontAwesomeIcons.userGraduate,
      category: IconCategory.education,
      keywords: ['graduate', 'student', 'diploma'],
    ),
    FaIconName(
      name: 'book',
      faIcon: FontAwesomeIcons.book,
      category: IconCategory.education,
      keywords: ['read', 'study', 'learn', 'library'],
    ),
    FaIconName(
      name: 'bookOpen',
      faIcon: FontAwesomeIcons.bookOpen,
      category: IconCategory.education,
      keywords: ['read', 'study', 'learn'],
    ),
    FaIconName(
      name: 'graduationCap',
      faIcon: FontAwesomeIcons.graduationCap,
      category: IconCategory.education,
      keywords: ['school', 'university', 'study', 'graduate'],
    ),
    FaIconName(
      name: 'school',
      faIcon: FontAwesomeIcons.school,
      category: IconCategory.education,
      keywords: ['education', 'learn', 'study'],
    ),
    FaIconName(
      name: 'chalkboard',
      faIcon: FontAwesomeIcons.chalkboard,
      category: IconCategory.education,
      keywords: ['teach', 'lesson', 'class'],
    ),
    FaIconName(
      name: 'language',
      faIcon: FontAwesomeIcons.language,
      category: IconCategory.education,
      keywords: ['translate', 'learn', 'speak'],
    ),
    FaIconName(
      name: 'flask',
      faIcon: FontAwesomeIcons.flask,
      category: IconCategory.education,
      keywords: ['science', 'chemistry', 'lab'],
    ),
    FaIconName(
      name: 'atom',
      faIcon: FontAwesomeIcons.atom,
      category: IconCategory.education,
      keywords: ['science', 'physics', 'chemistry'],
    ),
    FaIconName(
      name: 'microscope',
      faIcon: FontAwesomeIcons.microscope,
      category: IconCategory.education,
      keywords: ['science', 'biology', 'lab', 'research'],
    ),
    FaIconName(
      name: 'globe',
      faIcon: FontAwesomeIcons.globe,
      category: IconCategory.education,
      keywords: ['world', 'geography', 'earth'],
    ),
    FaIconName(
      name: 'newspaper',
      faIcon: FontAwesomeIcons.newspaper,
      category: IconCategory.education,
      keywords: ['news', 'read', 'article'],
    ),
    FaIconName(
      name: 'blog',
      faIcon: FontAwesomeIcons.blog,
      category: IconCategory.education,
      keywords: ['write', 'article', 'post'],
    ),

    // Travel
    FaIconName(
      name: 'cartFlatbedSuitcase',
      faIcon: FontAwesomeIcons.cartFlatbedSuitcase,
      category: IconCategory.travel,
      keywords: ['luggage', 'airport', 'baggage'],
    ),
    FaIconName(
      name: 'tent',
      faIcon: FontAwesomeIcons.tent,
      category: IconCategory.travel,
      keywords: ['camp', 'outdoor', 'nature'],
    ),
    FaIconName(
      name: 'rocket',
      faIcon: FontAwesomeIcons.rocket,
      category: IconCategory.travel,
      keywords: ['cab', 'transport', 'ride'],
    ),
    FaIconName(
      name: 'hotel',
      faIcon: FontAwesomeIcons.hotel,
      category: IconCategory.travel,
      keywords: ['stay', 'vacation', 'room'],
    ),
    FaIconName(
      name: 'suitcase',
      faIcon: FontAwesomeIcons.suitcase,
      category: IconCategory.travel,
      keywords: ['luggage', 'travel', 'vacation'],
    ),
    FaIconName(
      name: 'passport',
      faIcon: FontAwesomeIcons.passport,
      category: IconCategory.travel,
      keywords: ['document', 'travel', 'international'],
    ),
    FaIconName(
      name: 'map',
      faIcon: FontAwesomeIcons.map,
      category: IconCategory.travel,
      keywords: ['navigation', 'location', 'direction'],
    ),
    FaIconName(
      name: 'locationDot',
      faIcon: FontAwesomeIcons.locationDot,
      category: IconCategory.travel,
      keywords: ['pin', 'place', 'map', 'gps'],
    ),
    FaIconName(
      name: 'compass',
      faIcon: FontAwesomeIcons.compass,
      category: IconCategory.travel,
      keywords: ['navigation', 'direction', 'explore'],
    ),

    // Food
    FaIconName(
      name: 'blender',
      faIcon: FontAwesomeIcons.blender,
      category: IconCategory.food,
      keywords: ['kitchen', 'mix', 'smoothie'],
    ),
    FaIconName(
      name: 'bowlFood',
      faIcon: FontAwesomeIcons.bowlFood,
      category: IconCategory.food,
      keywords: ['meal', 'eat', 'dish'],
    ),
    FaIconName(
      name: 'bowlRice',
      faIcon: FontAwesomeIcons.bowlRice,
      category: IconCategory.food,
      keywords: ['meal', 'eat', 'asian'],
    ),
    FaIconName(
      name: 'utensils',
      faIcon: FontAwesomeIcons.utensils,
      category: IconCategory.food,
      keywords: ['eat', 'restaurant', 'dining', 'meal'],
    ),
    FaIconName(
      name: 'mugHot',
      faIcon: FontAwesomeIcons.mugHot,
      category: IconCategory.food,
      keywords: ['coffee', 'tea', 'drink', 'hot'],
    ),
    FaIconName(
      name: 'coffee',
      faIcon: FontAwesomeIcons.mugSaucer,
      category: IconCategory.food,
      keywords: ['drink', 'cafe', 'espresso'],
    ),
    FaIconName(
      name: 'wineGlass',
      faIcon: FontAwesomeIcons.wineGlass,
      category: IconCategory.food,
      keywords: ['drink', 'alcohol', 'bar'],
    ),
    FaIconName(
      name: 'beer',
      faIcon: FontAwesomeIcons.beerMugEmpty,
      category: IconCategory.food,
      keywords: ['drink', 'alcohol', 'bar', 'pub'],
    ),
    FaIconName(
      name: 'cocktail',
      faIcon: FontAwesomeIcons.martiniGlass,
      category: IconCategory.food,
      keywords: ['drink', 'bar', 'alcohol', 'party'],
    ),
    FaIconName(
      name: 'pizza',
      faIcon: FontAwesomeIcons.pizzaSlice,
      category: IconCategory.food,
      keywords: ['food', 'italian', 'fast food'],
    ),
    FaIconName(
      name: 'burger',
      faIcon: FontAwesomeIcons.burger,
      category: IconCategory.food,
      keywords: ['food', 'fast food', 'meal'],
    ),
    FaIconName(
      name: 'apple',
      faIcon: FontAwesomeIcons.appleWhole,
      category: IconCategory.food,
      keywords: ['fruit', 'healthy', 'food'],
    ),
    FaIconName(
      name: 'carrot',
      faIcon: FontAwesomeIcons.carrot,
      category: IconCategory.food,
      keywords: ['vegetable', 'healthy', 'food'],
    ),
    FaIconName(
      name: 'iceCream',
      faIcon: FontAwesomeIcons.iceCream,
      category: IconCategory.food,
      keywords: ['dessert', 'sweet', 'cold'],
    ),
    FaIconName(
      name: 'cookie',
      faIcon: FontAwesomeIcons.cookieBite,
      category: IconCategory.food,
      keywords: ['dessert', 'sweet', 'snack'],
    ),
    FaIconName(
      name: 'cake',
      faIcon: FontAwesomeIcons.cakeCandles,
      category: IconCategory.food,
      keywords: ['birthday', 'dessert', 'sweet', 'celebration'],
    ),
    FaIconName(
      name: 'shoppingCart',
      faIcon: FontAwesomeIcons.cartShopping,
      category: IconCategory.shopping,
      keywords: ['buy', 'store', 'grocery'],
    ),
    FaIconName(
      name: 'basket',
      faIcon: FontAwesomeIcons.basketShopping,
      category: IconCategory.food,
      keywords: ['buy', 'store', 'grocery'],
    ),

    // Nature
    FaIconName(
      name: 'sun',
      faIcon: FontAwesomeIcons.sun,
      category: IconCategory.nature,
      keywords: ['day', 'weather', 'light', 'sunny'],
    ),
    FaIconName(
      name: 'cloud',
      faIcon: FontAwesomeIcons.cloud,
      category: IconCategory.nature,
      keywords: ['weather', 'sky'],
    ),
    FaIconName(
      name: 'cloudRain',
      faIcon: FontAwesomeIcons.cloudRain,
      category: IconCategory.nature,
      keywords: ['weather', 'rain', 'storm'],
    ),
    FaIconName(
      name: 'snowflake',
      faIcon: FontAwesomeIcons.snowflake,
      category: IconCategory.nature,
      keywords: ['winter', 'cold', 'snow'],
    ),
    FaIconName(
      name: 'tree',
      faIcon: FontAwesomeIcons.tree,
      category: IconCategory.nature,
      keywords: ['plant', 'forest', 'nature'],
    ),
    FaIconName(
      name: 'leaf',
      faIcon: FontAwesomeIcons.leaf,
      category: IconCategory.nature,
      keywords: ['plant', 'nature', 'green'],
    ),
    FaIconName(
      name: 'seedling',
      faIcon: FontAwesomeIcons.seedling,
      category: IconCategory.nature,
      keywords: ['plant', 'grow', 'nature', 'garden'],
    ),
    FaIconName(
      name: 'mountain',
      faIcon: FontAwesomeIcons.mountain,
      category: IconCategory.nature,
      keywords: ['outdoor', 'hike', 'nature'],
    ),
    FaIconName(
      name: 'water',
      faIcon: FontAwesomeIcons.water,
      category: IconCategory.nature,
      keywords: ['sea', 'ocean', 'wave'],
    ),
    FaIconName(
      name: 'fire',
      faIcon: FontAwesomeIcons.fire,
      category: IconCategory.nature,
      keywords: ['hot', 'flame', 'campfire'],
    ),
    FaIconName(
      name: 'campground',
      faIcon: FontAwesomeIcons.campground,
      category: IconCategory.nature,
      keywords: ['tent', 'camp', 'outdoor'],
    ),
    FaIconName(
      name: 'dog',
      faIcon: FontAwesomeIcons.dog,
      category: IconCategory.animals,
      keywords: ['pet', 'animal', 'walk'],
    ),
    FaIconName(
      name: 'cat',
      faIcon: FontAwesomeIcons.cat,
      category: IconCategory.animals,
      keywords: ['pet', 'animal'],
    ),
    FaIconName(
      name: 'fish',
      faIcon: FontAwesomeIcons.fish,
      category: IconCategory.animals,
      keywords: ['animal', 'water', 'fishing'],
    ),
    FaIconName(
      name: 'paw',
      faIcon: FontAwesomeIcons.paw,
      category: IconCategory.animals,
      keywords: ['pet', 'animal', 'walk'],
    ),

    // Technology
    FaIconName(
      name: 'mobile',
      faIcon: FontAwesomeIcons.mobileScreen,
      category: IconCategory.technology,
      keywords: ['phone', 'smartphone', 'device'],
    ),
    FaIconName(
      name: 'tablet',
      faIcon: FontAwesomeIcons.tabletScreenButton,
      category: IconCategory.technology,
      keywords: ['device', 'ipad', 'screen'],
    ),
    FaIconName(
      name: 'keyboard',
      faIcon: FontAwesomeIcons.keyboard,
      category: IconCategory.technology,
      keywords: ['type', 'computer', 'input'],
    ),
    FaIconName(
      name: 'mouse',
      faIcon: FontAwesomeIcons.computerMouse,
      category: IconCategory.technology,
      keywords: ['click', 'computer', 'input'],
    ),
    FaIconName(
      name: 'printer',
      faIcon: FontAwesomeIcons.print,
      category: IconCategory.technology,
      keywords: ['print', 'document', 'office'],
    ),
    FaIconName(
      name: 'wifi',
      faIcon: FontAwesomeIcons.wifi,
      category: IconCategory.technology,
      keywords: ['internet', 'network', 'wireless'],
    ),
    FaIconName(
      name: 'bluetooth',
      faIcon: FontAwesomeIcons.bluetooth,
      category: IconCategory.technology,
      keywords: ['wireless', 'connect'],
    ),
    FaIconName(
      name: 'database',
      faIcon: FontAwesomeIcons.database,
      category: IconCategory.technology,
      keywords: ['data', 'storage', 'server'],
    ),
    FaIconName(
      name: 'server',
      faIcon: FontAwesomeIcons.server,
      category: IconCategory.technology,
      keywords: ['data', 'hosting', 'computer'],
    ),
    FaIconName(
      name: 'robot',
      faIcon: FontAwesomeIcons.robot,
      category: IconCategory.technology,
      keywords: ['ai', 'automation', 'machine'],
    ),
    FaIconName(
      name: 'microchip',
      faIcon: FontAwesomeIcons.microchip,
      category: IconCategory.technology,
      keywords: ['cpu', 'processor', 'hardware'],
    ),
    FaIconName(
      name: 'plug',
      faIcon: FontAwesomeIcons.plug,
      category: IconCategory.technology,
      keywords: ['power', 'electric', 'connect'],
    ),
    FaIconName(
      name: 'batteryFull',
      faIcon: FontAwesomeIcons.batteryFull,
      category: IconCategory.technology,
      keywords: ['power', 'charge', 'energy'],
    ),
    FaIconName(
      name: 'satelliteDish',
      faIcon: FontAwesomeIcons.satelliteDish,
      category: IconCategory.technology,
      keywords: ['signal', 'space', 'communication'],
    ),

    // Communication
    FaIconName(
      name: 'phone',
      faIcon: FontAwesomeIcons.phone,
      category: IconCategory.communication,
      keywords: ['call', 'contact', 'talk'],
    ),
    FaIconName(
      name: 'microphoneLines',
      faIcon: FontAwesomeIcons.microphoneLines,
      category: IconCategory.communication,
      keywords: ['speak', 'record', 'podcast'],
    ),
    FaIconName(
      name: 'envelope',
      faIcon: FontAwesomeIcons.envelope,
      category: IconCategory.communication,
      keywords: ['email', 'mail', 'message'],
    ),
    FaIconName(
      name: 'comment',
      faIcon: FontAwesomeIcons.comment,
      category: IconCategory.communication,
      keywords: ['message', 'chat', 'talk'],
    ),
    FaIconName(
      name: 'comments',
      faIcon: FontAwesomeIcons.comments,
      category: IconCategory.communication,
      keywords: ['chat', 'discussion', 'talk', 'conversation'],
    ),
    FaIconName(
      name: 'video',
      faIcon: FontAwesomeIcons.video,
      category: IconCategory.communication,
      keywords: ['call', 'meeting', 'camera'],
    ),
    FaIconName(
      name: 'microphone',
      faIcon: FontAwesomeIcons.microphone,
      category: IconCategory.communication,
      keywords: ['speak', 'record', 'voice', 'podcast'],
    ),
    FaIconName(
      name: 'bullhorn',
      faIcon: FontAwesomeIcons.bullhorn,
      category: IconCategory.communication,
      keywords: ['announce', 'marketing', 'speak'],
    ),
    FaIconName(
      name: 'bell',
      faIcon: FontAwesomeIcons.bell,
      category: IconCategory.communication,
      keywords: ['notification', 'alert', 'reminder'],
    ),
    FaIconName(
      name: 'share',
      faIcon: FontAwesomeIcons.shareNodes,
      category: IconCategory.communication,
      keywords: ['social', 'send', 'connect'],
    ),
    FaIconName(
      name: 'at',
      faIcon: FontAwesomeIcons.at,
      category: IconCategory.communication,
      keywords: ['email', 'mention', 'address'],
    ),
    FaIconName(
      name: 'hashtag',
      faIcon: FontAwesomeIcons.hashtag,
      category: IconCategory.communication,
      keywords: ['social', 'tag', 'trend'],
    ),
    FaIconName(
      name: 'rss',
      faIcon: FontAwesomeIcons.rss,
      category: IconCategory.communication,
      keywords: ['feed', 'news', 'subscribe'],
    ),

    // Objects
    FaIconName(
      name: 'home',
      faIcon: FontAwesomeIcons.house,
      category: IconCategory.objects,
      keywords: ['house', 'family', 'domestic'],
    ),
    FaIconName(
      name: 'couch',
      faIcon: FontAwesomeIcons.couch,
      category: IconCategory.objects,
      keywords: ['sofa', 'relax', 'home', 'living'],
    ),
    FaIconName(
      name: 'chair',
      faIcon: FontAwesomeIcons.chair,
      category: IconCategory.objects,
      keywords: ['sit', 'furniture', 'home'],
    ),
    FaIconName(
      name: 'clock',
      faIcon: FontAwesomeIcons.clock,
      category: IconCategory.time,
      keywords: ['time', 'watch', 'schedule'],
    ),
    FaIconName(
      name: 'stopwatch',
      faIcon: FontAwesomeIcons.stopwatch,
      category: IconCategory.time,
      keywords: ['time', 'timer', 'track'],
    ),
    FaIconName(
      name: 'hourglass',
      faIcon: FontAwesomeIcons.hourglassHalf,
      category: IconCategory.time,
      keywords: ['time', 'wait', 'timer'],
    ),
    FaIconName(
      name: 'key',
      faIcon: FontAwesomeIcons.key,
      category: IconCategory.objects,
      keywords: ['lock', 'security', 'access'],
    ),
    FaIconName(
      name: 'lock',
      faIcon: FontAwesomeIcons.lock,
      category: IconCategory.objects,
      keywords: ['security', 'password', 'private'],
    ),
    FaIconName(
      name: 'unlock',
      faIcon: FontAwesomeIcons.unlock,
      category: IconCategory.objects,
      keywords: ['open', 'access', 'security'],
    ),
    FaIconName(
      name: 'gift',
      faIcon: FontAwesomeIcons.gift,
      category: IconCategory.objects,
      keywords: ['present', 'birthday', 'celebration'],
    ),
    FaIconName(
      name: 'trophy',
      faIcon: FontAwesomeIcons.trophy,
      category: IconCategory.sportsFitness,
      keywords: ['win', 'achievement', 'award', 'goal'],
    ),
    FaIconName(
      name: 'medal',
      faIcon: FontAwesomeIcons.medal,
      category: IconCategory.sportsFitness,
      keywords: ['award', 'achievement', 'win'],
    ),
    FaIconName(
      name: 'star',
      faIcon: FontAwesomeIcons.star,
      category: IconCategory.objects,
      keywords: ['favorite', 'rating', 'important'],
    ),
    FaIconName(
      name: 'flag',
      faIcon: FontAwesomeIcons.flag,
      category: IconCategory.objects,
      keywords: ['goal', 'milestone', 'mark'],
    ),
    FaIconName(
      name: 'bookmark',
      faIcon: FontAwesomeIcons.bookmark,
      category: IconCategory.objects,
      keywords: ['save', 'favorite', 'mark'],
    ),
    FaIconName(
      name: 'tag',
      faIcon: FontAwesomeIcons.tag,
      category: IconCategory.shopping,
      keywords: ['label', 'price', 'category'],
    ),
    FaIconName(
      name: 'wallet',
      faIcon: FontAwesomeIcons.wallet,
      category: IconCategory.objects,
      keywords: ['money', 'finance', 'pay'],
    ),
    FaIconName(
      name: 'moneyBill',
      faIcon: FontAwesomeIcons.moneyBill,
      category: IconCategory.objects,
      keywords: ['cash', 'finance', 'pay', 'dollar'],
    ),
    FaIconName(
      name: 'creditCard',
      faIcon: FontAwesomeIcons.creditCard,
      category: IconCategory.shopping,
      keywords: ['pay', 'finance', 'bank'],
    ),
    FaIconName(
      name: 'piggyBank',
      faIcon: FontAwesomeIcons.piggyBank,
      category: IconCategory.objects,
      keywords: ['save', 'money', 'finance'],
    ),
    FaIconName(
      name: 'gem',
      faIcon: FontAwesomeIcons.gem,
      category: IconCategory.objects,
      keywords: ['diamond', 'premium', 'luxury'],
    ),
    FaIconName(
      name: 'bolt',
      faIcon: FontAwesomeIcons.bolt,
      category: IconCategory.objects,
      keywords: ['energy', 'power', 'fast', 'lightning'],
    ),
    FaIconName(
      name: 'wrench',
      faIcon: FontAwesomeIcons.wrench,
      category: IconCategory.objects,
      keywords: ['tool', 'fix', 'repair', 'settings'],
    ),
    FaIconName(
      name: 'hammer',
      faIcon: FontAwesomeIcons.hammer,
      category: IconCategory.objects,
      keywords: ['tool', 'build', 'work'],
    ),
    FaIconName(
      name: 'screwdriver',
      faIcon: FontAwesomeIcons.screwdriverWrench,
      category: IconCategory.objects,
      keywords: ['tool', 'fix', 'repair'],
    ),
    FaIconName(
      name: 'broom',
      faIcon: FontAwesomeIcons.broom,
      category: IconCategory.objects,
      keywords: ['clean', 'sweep', 'housework'],
    ),
    FaIconName(
      name: 'shower',
      faIcon: FontAwesomeIcons.shower,
      category: IconCategory.objects,
      keywords: ['bath', 'clean', 'hygiene'],
    ),
    FaIconName(
      name: 'shirt',
      faIcon: FontAwesomeIcons.shirt,
      category: IconCategory.objects,
      keywords: ['clothes', 'fashion', 'dress'],
    ),
    FaIconName(
      name: 'glasses',
      faIcon: FontAwesomeIcons.glasses,
      category: IconCategory.objects,
      keywords: ['see', 'read', 'vision'],
    ),
    FaIconName(
      name: 'umbrellaBeach',
      faIcon: FontAwesomeIcons.umbrellaBeach,
      category: IconCategory.objects,
      keywords: ['beach', 'vacation', 'relax', 'summer'],
    ),
    FaIconName(
      name: 'trash',
      faIcon: FontAwesomeIcons.trash,
      category: IconCategory.objects,
      keywords: ['delete', 'bin', 'garbage'],
    ),
    FaIconName(
      name: 'bong',
      faIcon: FontAwesomeIcons.bong,
      category: IconCategory.objects,
      keywords: ['smoke', 'waterpipe'],
    ),
    FaIconName(
      name: 'gemini',
      faIcon: FontAwesomeIcons.gemini,
      category: IconCategory.objects,
      keywords: ['zodiac', 'astrology', 'twins'],
    ),
    FaIconName(
      name: 'binoculars',
      faIcon: FontAwesomeIcons.binoculars,
      category: IconCategory.objects,
      keywords: ['watch', 'explore', 'birdwatching'],
    ),

    // Buildings
    FaIconName(
      name: 'house',
      faIcon: FontAwesomeIcons.house,
      category: IconCategory.buildings,
      keywords: ['home', 'residence'],
    ),
    FaIconName(
      name: 'houseChimney',
      faIcon: FontAwesomeIcons.houseChimney,
      category: IconCategory.buildings,
      keywords: ['home', 'cottage', 'house'],
    ),
    FaIconName(
      name: 'buildingColumns',
      faIcon: FontAwesomeIcons.buildingColumns,
      category: IconCategory.buildings,
      keywords: ['bank', 'museum', 'university', 'institution'],
    ),
    FaIconName(
      name: 'shop',
      faIcon: FontAwesomeIcons.shop,
      category: IconCategory.buildings,
      keywords: ['store', 'market', 'retail'],
    ),
    FaIconName(
      name: 'warehouse',
      faIcon: FontAwesomeIcons.warehouse,
      category: IconCategory.buildings,
      keywords: ['storage', 'industry', 'depot'],
    ),
    FaIconName(
      name: 'industry',
      faIcon: FontAwesomeIcons.industry,
      category: IconCategory.buildings,
      keywords: ['factory', 'plant', 'manufacturing'],
    ),
    FaIconName(
      name: 'city',
      faIcon: FontAwesomeIcons.city,
      category: IconCategory.buildings,
      keywords: ['skyline', 'downtown', 'urban'],
    ),
    FaIconName(
      name: 'landmark',
      faIcon: FontAwesomeIcons.landmark,
      category: IconCategory.buildings,
      keywords: ['courthouse', 'government', 'monument'],
    ),
    FaIconName(
      name: 'landmarkDome',
      faIcon: FontAwesomeIcons.landmarkDome,
      category: IconCategory.buildings,
      keywords: ['capitol', 'government', 'dome'],
    ),
    FaIconName(
      name: 'monument',
      faIcon: FontAwesomeIcons.monument,
      category: IconCategory.buildings,
      keywords: ['memorial', 'landmark', 'statue'],
    ),
    FaIconName(
      name: 'church',
      faIcon: FontAwesomeIcons.church,
      category: IconCategory.buildings,
      keywords: ['worship', 'religion', 'chapel'],
    ),
    FaIconName(
      name: 'mosque',
      faIcon: FontAwesomeIcons.mosque,
      category: IconCategory.buildings,
      keywords: ['worship', 'religion', 'islam'],
    ),
    FaIconName(
      name: 'synagogue',
      faIcon: FontAwesomeIcons.synagogue,
      category: IconCategory.buildings,
      keywords: ['worship', 'religion', 'judaism'],
    ),
    FaIconName(
      name: 'kaaba',
      faIcon: FontAwesomeIcons.kaaba,
      category: IconCategory.buildings,
      keywords: ['worship', 'religion', 'mecca'],
    ),
    FaIconName(
      name: 'placeOfWorship',
      faIcon: FontAwesomeIcons.placeOfWorship,
      category: IconCategory.buildings,
      keywords: ['worship', 'religion', 'temple'],
    ),
    FaIconName(
      name: 'toriiGate',
      faIcon: FontAwesomeIcons.toriiGate,
      category: IconCategory.buildings,
      keywords: ['shrine', 'japan', 'gate'],
    ),

    // Animals
    FaIconName(
      name: 'horse',
      faIcon: FontAwesomeIcons.horse,
      category: IconCategory.animals,
      keywords: ['pet', 'ride', 'farm'],
    ),
    FaIconName(
      name: 'dove',
      faIcon: FontAwesomeIcons.dove,
      category: IconCategory.animals,
      keywords: ['bird', 'peace', 'fly'],
    ),
    FaIconName(
      name: 'crow',
      faIcon: FontAwesomeIcons.crow,
      category: IconCategory.animals,
      keywords: ['bird', 'raven'],
    ),
    FaIconName(
      name: 'kiwiBird',
      faIcon: FontAwesomeIcons.kiwiBird,
      category: IconCategory.animals,
      keywords: ['bird'],
    ),
    FaIconName(
      name: 'frog',
      faIcon: FontAwesomeIcons.frog,
      category: IconCategory.animals,
      keywords: ['amphibian', 'pond'],
    ),
    FaIconName(
      name: 'spider',
      faIcon: FontAwesomeIcons.spider,
      category: IconCategory.animals,
      keywords: ['bug', 'insect', 'web'],
    ),

    // Gaming
    FaIconName(
      name: 'chess',
      faIcon: FontAwesomeIcons.chess,
      category: IconCategory.gaming,
      keywords: ['game', 'strategy', 'board'],
    ),
    FaIconName(
      name: 'dice',
      faIcon: FontAwesomeIcons.dice,
      category: IconCategory.gaming,
      keywords: ['game', 'chance', 'roll'],
    ),
    FaIconName(
      name: 'puzzlePiece',
      faIcon: FontAwesomeIcons.puzzlePiece,
      category: IconCategory.gaming,
      keywords: ['puzzle', 'game', 'solve'],
    ),

    // Religion
    FaIconName(
      name: 'bookBible',
      faIcon: FontAwesomeIcons.bookBible,
      category: IconCategory.religion,
      keywords: ['christianity', 'scripture', 'read'],
    ),
    FaIconName(
      name: 'bookQuran',
      faIcon: FontAwesomeIcons.bookQuran,
      category: IconCategory.religion,
      keywords: ['islam', 'scripture', 'read'],
    ),
    FaIconName(
      name: 'bookTanakh',
      faIcon: FontAwesomeIcons.bookTanakh,
      category: IconCategory.religion,
      keywords: ['judaism', 'scripture', 'read'],
    ),
    FaIconName(
      name: 'peace',
      faIcon: FontAwesomeIcons.peace,
      category: IconCategory.religion,
      keywords: ['symbol', 'calm', 'harmony'],
    ),
    FaIconName(
      name: 'cross',
      faIcon: FontAwesomeIcons.cross,
      category: IconCategory.religion,
      keywords: ['christianity', 'faith'],
    ),
    FaIconName(
      name: 'starOfDavid',
      faIcon: FontAwesomeIcons.starOfDavid,
      category: IconCategory.religion,
      keywords: ['judaism', 'faith'],
    ),
    FaIconName(
      name: 'om',
      faIcon: FontAwesomeIcons.om,
      category: IconCategory.religion,
      keywords: ['hinduism', 'buddhism', 'meditation'],
    ),
    FaIconName(
      name: 'yinYang',
      faIcon: FontAwesomeIcons.yinYang,
      category: IconCategory.religion,
      keywords: ['taoism', 'balance'],
    ),
    FaIconName(
      name: 'dharmachakra',
      faIcon: FontAwesomeIcons.dharmachakra,
      category: IconCategory.religion,
      keywords: ['buddhism', 'faith'],
    ),
    FaIconName(
      name: 'handsPraying',
      faIcon: FontAwesomeIcons.handsPraying,
      category: IconCategory.religion,
      keywords: ['pray', 'faith', 'worship'],
    ),

    // Shopping
    FaIconName(
      name: 'bagShopping',
      faIcon: FontAwesomeIcons.bagShopping,
      category: IconCategory.shopping,
      keywords: ['bag', 'store', 'buy'],
    ),
    FaIconName(
      name: 'receipt',
      faIcon: FontAwesomeIcons.receipt,
      category: IconCategory.shopping,
      keywords: ['bill', 'invoice', 'purchase'],
    ),
    FaIconName(
      name: 'barcode',
      faIcon: FontAwesomeIcons.barcode,
      category: IconCategory.shopping,
      keywords: ['scan', 'product', 'price'],
    ),

    // Time
    FaIconName(
      name: 'alarmClock',
      faIcon: FontAwesomeIcons.alarmClock,
      category: IconCategory.time,
      keywords: ['wake', 'alert', 'morning'],
    ),
    FaIconName(
      name: 'businessTime',
      faIcon: FontAwesomeIcons.businessTime,
      category: IconCategory.time,
      keywords: ['work', 'schedule', 'office'],
    ),

    // Transportation
    FaIconName(
      name: 'plane',
      faIcon: FontAwesomeIcons.plane,
      category: IconCategory.transportation,
      keywords: ['flight', 'airport', 'travel', 'vacation'],
    ),
    FaIconName(
      name: 'planeDeparture',
      faIcon: FontAwesomeIcons.planeDeparture,
      category: IconCategory.transportation,
      keywords: ['flight', 'airport', 'travel'],
    ),
    FaIconName(
      name: 'jetFighterUp',
      faIcon: FontAwesomeIcons.jetFighterUp,
      category: IconCategory.transportation,
      keywords: ['jet', 'military', 'fly'],
    ),
    FaIconName(
      name: 'car',
      faIcon: FontAwesomeIcons.car,
      category: IconCategory.transportation,
      keywords: ['drive', 'vehicle', 'auto', 'transport'],
    ),
    FaIconName(
      name: 'bus',
      faIcon: FontAwesomeIcons.bus,
      category: IconCategory.transportation,
      keywords: ['transport', 'public', 'commute'],
    ),
    FaIconName(
      name: 'busSimple',
      faIcon: FontAwesomeIcons.busSimple,
      category: IconCategory.transportation,
      keywords: ['transport', 'public', 'commute'],
    ),
    FaIconName(
      name: 'busSide',
      faIcon: FontAwesomeIcons.busSide,
      category: IconCategory.transportation,
      keywords: ['transport', 'public', 'commute'],
    ),
    FaIconName(
      name: 'train',
      faIcon: FontAwesomeIcons.train,
      category: IconCategory.transportation,
      keywords: ['transport', 'railway', 'commute'],
    ),
    FaIconName(
      name: 'subway',
      faIcon: FontAwesomeIcons.trainSubway,
      category: IconCategory.transportation,
      keywords: ['metro', 'transport', 'commute'],
    ),
    FaIconName(
      name: 'bicycle',
      faIcon: FontAwesomeIcons.bicycle,
      category: IconCategory.transportation,
      keywords: ['bike', 'cycling', 'transport'],
    ),
    FaIconName(
      name: 'motorcycle',
      faIcon: FontAwesomeIcons.motorcycle,
      category: IconCategory.transportation,
      keywords: ['bike', 'ride', 'transport'],
    ),
    FaIconName(
      name: 'ship',
      faIcon: FontAwesomeIcons.ship,
      category: IconCategory.transportation,
      keywords: ['boat', 'cruise', 'sea', 'water'],
    ),
    FaIconName(
      name: 'taxi',
      faIcon: FontAwesomeIcons.taxi,
      category: IconCategory.transportation,
      keywords: ['cab', 'transport', 'ride'],
    ),
    FaIconName(
      name: 'truck',
      faIcon: FontAwesomeIcons.truck,
      category: IconCategory.transportation,
      keywords: ['transport', 'ride', 'vacation'],
    ),
    FaIconName(
      name: 'helicopter',
      faIcon: FontAwesomeIcons.helicopter,
      category: IconCategory.transportation,
      keywords: ['fly', 'air', 'rescue'],
    ),
    FaIconName(
      name: 'cableCar',
      faIcon: FontAwesomeIcons.cableCar,
      category: IconCategory.transportation,
      keywords: ['gondola', 'mountain', 'ride'],
    ),
    FaIconName(
      name: 'shuttleSpace',
      faIcon: FontAwesomeIcons.shuttleSpace,
      category: IconCategory.transportation,
      keywords: ['space', 'rocket', 'nasa'],
    ),
    FaIconName(
      name: 'snowplow',
      faIcon: FontAwesomeIcons.snowplow,
      category: IconCategory.transportation,
      keywords: ['winter', 'snow', 'clear'],
    ),
    FaIconName(
      name: 'gasPump',
      faIcon: FontAwesomeIcons.gasPump,
      category: IconCategory.transportation,
      keywords: ['fuel', 'car', 'station'],
    ),
  ];

  /// Get icons filtered by category.
  static List<FaIconName> getByCategory(IconCategory category) {
    if (category == IconCategory.all) return icons;
    return icons.where((icon) => icon.category == category).toList();
  }

  /// Search icons by name or keywords.
  static List<FaIconName> search(String query, {IconCategory? category}) {
    final lowerQuery = query.toLowerCase().trim();
    if (lowerQuery.isEmpty) {
      return category != null ? getByCategory(category) : icons;
    }

    var result = icons.where((icon) {
      final matchesName = icon.name.toLowerCase().contains(lowerQuery);
      final matchesKeyword = icon.keywords.any(
        (keyword) => keyword.toLowerCase().contains(lowerQuery),
      );
      return matchesName || matchesKeyword;
    });

    if (category != null && category != IconCategory.all) {
      result = result.where((icon) => icon.category == category);
    }

    return result.toList();
  }

  /// Find icon by id.
  static FaIconName findById(String id) => icons.firstWhere(
    (icon) => icon.id == id,
    orElse: () => defaultIcon,
  );

  /// Find icon by IconData.
  static FaIconName findByIconData(FaIconData faIcon) => icons.firstWhere(
    (icon) => icon.faIcon == faIcon,
    orElse: () => defaultIcon,
  );

  /// Default icon when no icon is selected.
  static final defaultIcon = const FaIconName(
    name: 'circle',
    faIcon: FontAwesomeIcons.circle,
    category: IconCategory.objects,
    keywords: ['default', 'shape'],
  );
}
