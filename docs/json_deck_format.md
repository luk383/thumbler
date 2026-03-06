# Thumbler JSON Deck Format

Thumbler supports a standardized local deck format with backward compatibility
for older list-based packs and legacy `items` wrappers.

## Preferred Root Shape

```json
{
  "id": "comptia_security_plus_sy0_701",
  "title": "CompTIA Security+",
  "examCode": "SY0-701",
  "category": "Cybersecurity",
  "description": "Security+ practice questions and review cards.",
  "version": "1",
  "questionCount": 1,
  "domains": [
    "General Security Concepts",
    "Threats and Vulnerabilities"
  ],
  "defaultContentType": "exam_question",
  "questions": [
    {
      "id": "sec701_q_001",
      "domain": "General Security Concepts",
      "topic": "CIA Triad",
      "subtopic": "Availability",
      "objectiveId": "1.1",
      "difficulty": 1,
      "question": "Which security principle ensures systems remain accessible to authorized users?",
      "answers": [
        "Confidentiality",
        "Integrity",
        "Availability",
        "Authentication"
      ],
      "correctIndex": 2,
      "explanation": "Availability ensures authorized users can access systems and data when needed."
    }
  ]
}
```

## Reference Implementation

The Security+ SY0-701 deck set is the canonical reference for the standardized
Thumbler format. Use these files as the source of truth when authoring new exam
or subject decks:

- `assets/decks/sec701_exam_pack_20.json`
- `assets/decks/sec701_exam_pack_30_a.json`
- `assets/decks/sec701_exam_simulation_90.json`
- `docs/question_batches/security_plus/*.batch.json`

## Supported Field Mapping

Root metadata:

- `id`
- `title` or legacy `name`
- `examCode`
- `category`
- `description`
- `version`
- `questionCount`
- `domains`
- `questions` or legacy `items`
- optional `defaultContentType`

Question fields:

- `id`
- `domain` or legacy `category`
- `topic`
- `subtopic`
- `objectiveId`
- `difficulty`
- `question` or legacy `promptText`
- `answers` or legacy `options`
- `correctIndex` or legacy `correctAnswerIndex`
- `explanation` or legacy `explanationText`
- `type` or legacy `contentType`
- optional `tags` (ignored safely if present)

`questionCount` is optional metadata, but if provided it should match the real
number of entries in `questions`/`items`.

## Backward Compatibility

Thumbler still accepts:

1. a raw JSON array of questions/items
2. legacy wrapped packs using:
   - `name`
   - `items`
   - `promptText`
   - `options`
   - `correctAnswerIndex`
   - `category`

If `type` / `contentType` is omitted:

- wrapped `questions` decks default to `exam_question`
- wrapped `items` decks default to `micro_card`
- raw arrays should continue to provide `contentType` explicitly

## Starter Templates

Starter templates live under `docs/deck_templates/` so they do not appear in
the in-app Library.

Available templates:

- `aws_cloud_practitioner.template.json`
- `aws_solutions_architect_associate.template.json`
- `general_knowledge_subject.template.json`
- `linux_essentials.template.json`

## How To Add A New Deck

1. Duplicate the closest template from `docs/deck_templates/`.
   - Use an exam template for certification-style decks.
   - Use `general_knowledge_subject.template.json` for topic/subject decks.
2. Replace metadata:
   - `id`
   - `title`
   - `examCode`
   - `category`
   - `description`
   - `version`
   - `domains`
3. Replace placeholder questions with real content.
4. Keep question ids stable and unique inside the deck.
5. When the deck is ready, copy it into `assets/decks/`.
6. Launch the app and use Library to verify the deck metadata and question count.

## Practical Notes

- Use `questions` for new decks.
- Use `domain` instead of `category` for new questions.
- Use `question`, `answers`, `correctIndex`, and `explanation` for new decks.
- Keep `defaultContentType` explicit when the whole deck is exam-only.
- Keep `questionCount` aligned with the real question list length.
- Do not store template files in `assets/decks/`, or they will show up as real packs.
