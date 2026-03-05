import '../domain/lesson.dart';

const List<Lesson> mockLessons = [
  Lesson(
    id: '1',
    category: '🧠 Psychology',
    hook: 'Your brain processes an image in just 13 milliseconds.',
    explanation:
        'The human visual system is astonishingly fast — far quicker than conscious thought. This is why first impressions happen almost instantly, before we can reason about them.',
    quizQuestion: 'How fast does the brain process a visual image?',
    options: ['13 milliseconds', '100 milliseconds', '500 milliseconds'],
    correctAnswerIndex: 0,
  ),
  Lesson(
    id: '2',
    category: '🔬 Science',
    hook: 'An ant colony behaves like a single giant brain.',
    explanation:
        'Colonies exhibit complex problem-solving — finding shortest paths, adjusting to food sources, even "making decisions" — with no central coordinator. It\'s called emergent intelligence.',
    quizQuestion: 'What concept describes ant-colony intelligence?',
    options: ['Hive mind', 'Distributed computing', 'Emergent intelligence'],
    correctAnswerIndex: 2,
  ),
  Lesson(
    id: '3',
    category: '📚 History',
    hook: 'The sandwich was invented so a man could keep gambling.',
    explanation:
        'John Montagu, the 4th Earl of Sandwich, asked servants to bring meat between bread so he wouldn\'t leave the card table. The year: 1762.',
    quizQuestion: 'Why did the Earl of Sandwich invent the sandwich?',
    options: [
      'To eat while working',
      'To keep gambling',
      'To feed soldiers faster',
    ],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: '4',
    category: '💡 Technology',
    hook: 'HTTPS doesn\'t hide who you\'re talking to — only what you say.',
    explanation:
        'TLS protects your request payload, but your ISP can still see the domain name via DNS and SNI. VPNs cover that gap by encrypting the full connection.',
    quizQuestion: 'What does HTTPS NOT hide from your ISP?',
    options: ['Domain name', 'Password', 'Page content'],
    correctAnswerIndex: 0,
  ),
  Lesson(
    id: '5',
    category: '🌍 Science',
    hook: 'The sky is blue because air molecules prefer blue light.',
    explanation:
        'Rayleigh scattering: shorter (blue) wavelengths collide more with atmospheric molecules and scatter everywhere. At sunset, light travels further through air, scattering away the blue and leaving red.',
    quizQuestion: 'What phenomenon makes the sky blue?',
    options: ['Refraction', 'Absorption', 'Rayleigh scattering'],
    correctAnswerIndex: 2,
  ),
  Lesson(
    id: '6',
    category: '🧬 Biology',
    hook: 'If you uncoiled all the DNA in your body, it would reach Pluto.',
    explanation:
        'Each cell contains ~2 metres of DNA. With ~37 trillion cells, that\'s ~70 billion km — the distance to Pluto and back. All tightly packed into a nucleus 6 micrometres wide.',
    quizQuestion: 'How much DNA is in each human cell (uncoiled)?',
    options: ['2 centimetres', '2 metres', '2 kilometres'],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: '7',
    category: '💰 Economics',
    hook: 'Every choice has a hidden cost: the best thing you didn\'t do.',
    explanation:
        'Opportunity cost is the value of the next-best alternative foregone. College isn\'t just tuition — it\'s also 4 years of potential salary. Economists always ask "compared to what?"',
    quizQuestion: 'What is opportunity cost?',
    options: [
      'Hidden taxes on transactions',
      'The price of a product',
      'The value of the best alternative forgone',
    ],
    correctAnswerIndex: 2,
  ),
  Lesson(
    id: '8',
    category: '🎨 Art & Nature',
    hook: 'Sunflowers arrange their seeds using an irrational number.',
    explanation:
        'Sunflower seeds follow Fibonacci spirals. The golden ratio (≈1.618) produces the least overlap, packing the most seeds. Nature discovered optimal geometry long before humans.',
    quizQuestion: 'What number governs sunflower seed arrangement?',
    options: ['Pi (π)', 'The golden ratio (φ)', 'Euler\'s number (e)'],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: '9',
    category: '🚀 Space',
    hook: 'A black hole the size of a coin would outweigh Mount Everest.',
    explanation:
        'Black holes have extreme density. The singularity is mathematically a point of infinite density — physics equations break down there. Even light cannot escape once past the event horizon.',
    quizQuestion: 'What happens at the singularity of a black hole?',
    options: [
      'Physics equations break down',
      'Matter is destroyed',
      'Time reverses',
    ],
    correctAnswerIndex: 0,
  ),
  Lesson(
    id: '10',
    category: '🧪 Chemistry',
    hook: 'Salt makes ice melt — and get colder at the same time.',
    explanation:
        'Salt lowers the freezing point of water (freezing point depression). The dissolving process is endothermic, absorbing heat from surroundings. Salted ice can reach −21°C — colder than pure ice.',
    quizQuestion: 'Why does salt lower the freezing point of water?',
    options: [
      'It adds heat to the water',
      'It disrupts ice crystal formation',
      'It raises the temperature',
    ],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: '11',
    category: '🧲 Physics',
    hook: 'No one knows why magnets attract — even physicists find it strange.',
    explanation:
        'Magnetism is a relativistic effect of moving electric charges. Richard Feynman famously explained that asking "why" magnets attract leads to an infinite regress — at some point we just accept the laws of nature.',
    quizQuestion: 'What is magnetism fundamentally a consequence of?',
    options: [
      'Gravity bending space',
      'Nuclear force overflow',
      'Moving electric charges',
    ],
    correctAnswerIndex: 2,
  ),
  Lesson(
    id: '12',
    category: '🗣️ Language',
    hook: 'There are ~7,000 languages on Earth — and one dies every two weeks.',
    explanation:
        'Most languages are spoken by fewer than 10,000 people. When the last speaker dies, millennia of knowledge — plants, history, ways of thinking — disappears with it. Half may be gone by 2100.',
    quizQuestion: 'How often does a language go extinct on average?',
    options: ['Every day', 'Every two weeks', 'Every month'],
    correctAnswerIndex: 1,
  ),
];
