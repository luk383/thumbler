import '../domain/lesson.dart';

const List<Lesson> mockLessons = [
  Lesson(
    id: 'aws_seed_1',
    category: 'AWS Architecture',
    hook:
        'Multi-AZ protects availability inside a Region, not from Region-wide failure.',
    explanation:
        'Use Multi-AZ for high availability within one Region and multi-Region patterns for disaster recovery.',
    quizQuestion: 'What risk does a Multi-AZ design primarily reduce?',
    options: [
      'A single Availability Zone failure',
      'An IAM policy misconfiguration',
      'A Region-wide outage',
    ],
    correctAnswerIndex: 0,
  ),
  Lesson(
    id: 'aws_seed_2',
    category: 'AWS Security',
    hook:
        'IAM roles eliminate the need to distribute long-term credentials to workloads.',
    explanation:
        'Roles provide temporary credentials and are the default secure choice for AWS-native applications.',
    quizQuestion: 'Why are IAM roles preferred over shared access keys?',
    options: [
      'They are cheaper',
      'They provide temporary credentials',
      'They remove the need for permissions',
    ],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: 'aws_seed_3',
    category: 'AWS Architecture',
    hook:
        'S3 event notifications are a common way to trigger serverless workflows.',
    explanation:
        'An object upload can emit an event to Lambda, SNS, or SQS and start downstream processing automatically.',
    quizQuestion: 'What can an S3 event notification do?',
    options: [
      'Trigger Lambda after an object upload',
      'Replace IAM policies',
      'Patch EC2 instances automatically',
    ],
    correctAnswerIndex: 0,
  ),
  Lesson(
    id: 'aws_seed_4',
    category: 'AWS Security',
    hook: 'Security groups are stateful, while network ACLs are stateless.',
    explanation:
        'Stateful filtering automatically allows response traffic. Stateless filters require explicit inbound and outbound rules.',
    quizQuestion: 'Which AWS network control is stateful?',
    options: ['Network ACL', 'Security group', 'Route table'],
    correctAnswerIndex: 1,
  ),
  Lesson(
    id: 'aws_seed_5',
    category: 'AWS Security',
    hook:
        'KMS centralizes key management, auditing, and rotation for encrypted AWS services.',
    explanation:
        'Using KMS improves operational control and integrates with CloudTrail for key usage visibility.',
    quizQuestion:
        'Which service is used to manage encryption keys centrally in AWS?',
    options: ['CloudFormation', 'KMS', 'Config'],
    correctAnswerIndex: 1,
  ),
];
