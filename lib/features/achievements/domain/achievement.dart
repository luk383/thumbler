class Achievement {
  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final String category;
}

/// All app achievements — evaluated against runtime data
const allAchievements = [
  // Study
  Achievement(id: 'first_card', emoji: '🃏', title: 'Prima carta', description: 'Rispondi alla prima domanda', category: 'Studio'),
  Achievement(id: 'centurion', emoji: '💯', title: 'Centurione', description: '100 risposte date', category: 'Studio'),
  Achievement(id: 'scholar', emoji: '🎓', title: 'Studioso', description: '500 risposte date', category: 'Studio'),
  Achievement(id: 'week_streak', emoji: '🔥', title: 'Settimana di fuoco', description: 'Streak di 7 giorni', category: 'Studio'),
  Achievement(id: 'month_streak', emoji: '🌟', title: 'Veterano', description: 'Streak di 30 giorni', category: 'Studio'),
  Achievement(id: 'card_creator', emoji: '✍️', title: 'Autore', description: 'Crea la prima carta personalizzata', category: 'Studio'),
  // Habits
  Achievement(id: 'habit_starter', emoji: '🌱', title: 'Primo passo', description: 'Aggiungi la prima abitudine', category: 'Abitudini'),
  Achievement(id: 'week_habit', emoji: '📅', title: 'Costante', description: '7 giorni consecutivi su un\'abitudine', category: 'Abitudini'),
  Achievement(id: 'month_habit', emoji: '🏆', title: 'Campione', description: '30 giorni consecutivi su un\'abitudine', category: 'Abitudini'),
  // Goals
  Achievement(id: 'goal_setter', emoji: '🎯', title: 'Pianificatore', description: 'Crea il primo obiettivo', category: 'Obiettivi'),
  Achievement(id: 'milestone_master', emoji: '🚀', title: 'Milestone Master', description: 'Completa 5 milestone', category: 'Obiettivi'),
  Achievement(id: 'goal_complete', emoji: '🥇', title: 'Obiettivo raggiunto', description: 'Completa il primo obiettivo', category: 'Obiettivi'),
  // Journal
  Achievement(id: 'first_entry', emoji: '📓', title: 'Diario aperto', description: 'Scrivi la prima nota', category: 'Diario'),
  Achievement(id: 'journalist', emoji: '🖊️', title: 'Giornalista', description: '10 note nel diario', category: 'Diario'),
  // Reflection
  Achievement(id: 'reflective', emoji: '🧘', title: 'Riflessivo', description: 'Prima riflessione settimanale', category: 'Riflessione'),
  Achievement(id: 'consistent_reflector', emoji: '🌙', title: 'Consistente', description: '4 riflessioni settimanali', category: 'Riflessione'),
  // Reading
  Achievement(id: 'bookworm', emoji: '📖', title: 'Lettore', description: 'Completa il primo libro/corso', category: 'Letture'),
  Achievement(id: 'voracious', emoji: '🦁', title: 'Vorace', description: '5 letture completate', category: 'Letture'),
  // Pomodoro
  Achievement(id: 'first_pomodoro', emoji: '🍅', title: 'Primo Pomodoro', description: 'Completa la prima sessione', category: 'Pomodoro'),
  Achievement(id: 'focused', emoji: '🧠', title: 'Focalizzato', description: '10 pomodori completati', category: 'Pomodoro'),
];
