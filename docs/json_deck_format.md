# Wolf Lab JSON Deck Format

Wolf Lab ships offline-first AWS certification decks. New deck assets should
follow the normalized format below so they work across Feed, Study, Exam, and
progress analytics.

## Preferred Root Shape

```json
{
  "id": "aws_certified_solutions_architect_associate_saa_c03",
  "provider": "aws",
  "certificationId": "aws_saa",
  "certificationTitle": "AWS Certified Solutions Architect - Associate",
  "track": "Associate",
  "aliases": ["aws_solutions_architect_associate_saa_c03"],
  "title": "AWS Certified Solutions Architect - Associate",
  "examCode": "SAA-C03",
  "category": "AWS Architecture",
  "description": "Offline study deck with flashcards and scenario-based practice questions.",
  "version": "2",
  "questionCount": 1,
  "domains": ["Design Secure Architectures"],
  "tags": ["aws", "aws_saa", "saa-c03", "associate"],
  "defaultContentType": "micro_card",
  "questions": [
    {
      "id": "saa_c03_fc_01_01",
      "type": "micro_card",
      "domainId": "saa-secure",
      "domain": "Design Secure Architectures",
      "topic": "IAM",
      "subtopic": "Least Privilege",
      "objectiveId": "1.1",
      "difficulty": 1,
      "tags": ["aws_saa", "saa-c03", "iam", "least-privilege"],
      "question": "Which statement best describes least privilege roles in AWS?",
      "answers": [
        "Use IAM roles and policies that grant only the permissions required by the workload.",
        "They replace all network controls.",
        "They are only for on-premises systems."
      ],
      "correctIndex": 0,
      "explanation": "Least privilege reduces blast radius and keeps permissions aligned to workload needs."
    }
  ]
}
```

## Reference Implementation

Use the bundled AWS decks as the reference for new certification content:

- `assets/decks/aws_certified_solutions_architect_associate_saa_c03.json`
- `assets/decks/aws_certified_security_specialty_scs_c02.json`
- `docs/question_batches/aws_certified_solutions_architect_associate/*.batch.json`
- `docs/question_batches/aws_certified_security_specialty/*.batch.json`

## Supported Root Fields

- `id`
- `provider`
- `certificationId`
- `certificationTitle`
- `track`
- `aliases`
- `title`
- `examCode`
- `category`
- `description`
- `version`
- `questionCount`
- `domains`
- `tags`
- `questions` or legacy `items`
- optional `defaultContentType`

## Supported Question Fields

- `id`
- `type` or legacy `contentType`
- `domainId`
- `domain` or legacy `category`
- `topic`
- `subtopic`
- `objectiveId`
- `difficulty`
- `tags`
- `question` or legacy `promptText`
- `answers` or legacy `options`
- `correctIndex` or legacy `correctAnswerIndex`
- `explanation` or legacy `explanationText`

Practice questions should always include answer choices, a correct answer,
explanations, topic tags, and difficulty.

## Backward Compatibility

Wolf Lab still accepts:

1. raw arrays of question entries
2. wrapped legacy packs using `name`, `items`, `promptText`, `options`,
   `correctAnswerIndex`, and `category`

If `type` / `contentType` is omitted:

- wrapped `questions` decks default to `exam_question`
- wrapped `items` decks default to `micro_card`
- raw arrays should continue to provide `contentType` explicitly

## Templates

Starter templates live under `docs/deck_templates/` so they do not appear in
the in-app library.

Available templates:

- `aws_certified_solutions_architect_associate.template.json`
- `aws_certified_security_specialty.template.json`

## How To Add A New Certification Deck

1. Duplicate the closest template from `docs/deck_templates/`.
2. Replace certification metadata:
   - `id`
   - `provider`
   - `certificationId`
   - `certificationTitle`
   - `track`
   - `examCode`
   - `category`
   - `domains`
   - `tags`
3. Add feed-ready `micro_card` entries and `exam_question` entries.
4. Keep `domainId` stable across decks and releases.
5. Keep question IDs stable and unique inside the deck.
6. Copy the finished deck into `assets/decks/`.

## Practical Notes

- Keep decks offline-first with no remote dependencies.
- Prefer `questions` for new assets.
- Use `domainId` plus `domain` to keep analytics stable when copy changes.
- Use `aliases` when renaming existing deck IDs so old progress can be migrated.
- Do not place draft or template decks in `assets/decks/`, or they will appear
  in the in-app library.
