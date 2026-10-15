package com.bytebattle.onboarding;

import com.bytebattle.curriculum.Topic;
import com.bytebattle.curriculum.TopicRepository;
import com.bytebattle.onboarding.OnboardingQuestion.Option;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/** The fixed onboarding questions. The two self-assessment questions list the active curriculum topics. */
@Component
public class OnboardingQuestionnaire {

    private final TopicRepository topicRepository;

    public OnboardingQuestionnaire(TopicRepository topicRepository) {
        this.topicRepository = topicRepository;
    }

    public List<OnboardingQuestion> questions() {
        List<Option> topics = topicRepository.findAll().stream()
                .filter(t -> Boolean.TRUE.equals(t.getActive()))
                .sorted(java.util.Comparator.comparing(Topic::getName))
                .map(t -> new Option(t.getSlug(), t.getName()))
                .toList();

        return List.of(
                new OnboardingQuestion("technicalExperience", "How would you describe your programming experience?",
                        "SINGLE_CHOICE", true, null, false, List.of(
                        new Option("BEGINNER", "I am just starting out"),
                        new Option("INTERMEDIATE", "I can build small programs on my own"),
                        new Option("ADVANCED", "I am comfortable with advanced topics"))),
                new OnboardingQuestion("preferredLanguage", "Which language do you want to practice in?",
                        "SINGLE_CHOICE", true, null, false, List.of(
                        new Option("JAVA", "Java"), new Option("PYTHON", "Python"),
                        new Option("JAVASCRIPT", "JavaScript"), new Option("CPP", "C++"), new Option("C", "C"))),
                new OnboardingQuestion("careerGoal", "What are you preparing for?",
                        "SINGLE_CHOICE", true, null, true, List.of(
                        new Option("Campus placements", "Campus placements"),
                        new Option("Technical interviews", "Technical interviews"),
                        new Option("Strengthening my fundamentals", "Strengthening my fundamentals"),
                        new Option("Becoming a backend developer", "Becoming a backend developer"))),
                new OnboardingQuestion("learningStyle", "What do you want from your learning?",
                        "SINGLE_CHOICE", true, null, false, List.of(
                        new Option("INTERVIEW_PREP", "Be ready for interview questions"),
                        new Option("EXAM_READY", "Be ready for exams and tests"),
                        new Option("CONCEPTUAL_DEPTH", "Understand concepts deeply"),
                        new Option("AUDITORY", "Learn by listening and talking it through"))),
                new OnboardingQuestion("explanationStyle", "How should new concepts be explained to you?",
                        "SINGLE_CHOICE", true, null, false, List.of(
                        new Option("STORY", "As a story"), new Option("FUN", "Light and fun"),
                        new Option("CINEMATIC", "Vivid and cinematic"),
                        new Option("DIRECT", "Short and technical, no storytelling"))),
                new OnboardingQuestion("interests", "What are you interested in? We use it for examples (pick up to 5).",
                        "MULTI_SELECT", false, 5, true, List.of(
                        new Option("cricket", "Cricket"), new Option("football", "Football"),
                        new Option("gaming", "Gaming"), new Option("movies", "Movies"),
                        new Option("music", "Music"), new Option("cooking", "Cooking"),
                        new Option("travel", "Travel"), new Option("anime", "Anime"))),
                new OnboardingQuestion("dailyGoalMinutes", "How much time can you practice each day?",
                        "NUMBER_CHOICE", true, null, false, List.of(
                        new Option("15", "15 minutes"), new Option("30", "30 minutes"),
                        new Option("60", "1 hour"), new Option("90", "1.5 hours"))),
                new OnboardingQuestion("confidenceAreas", "Which topics do you already feel confident in?",
                        "MULTI_SELECT", false, null, false, topics),
                new OnboardingQuestion("difficultyAreas", "Which topics do you find difficult?",
                        "MULTI_SELECT", false, null, false, topics));
    }

    /** Slugs a learner may reference in confidenceAreas / difficultyAreas. */
    public Set<String> topicSlugs() {
        return questions().stream()
                .filter(q -> q.id().equals("confidenceAreas"))
                .flatMap(q -> q.options().stream())
                .map(Option::value)
                .collect(Collectors.toSet());
    }
}
