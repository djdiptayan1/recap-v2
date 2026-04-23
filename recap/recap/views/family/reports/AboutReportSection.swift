//
//  AboutReportSection.swift
//  recap
//
//  Created by Copilot on 01/03/26.
//

import SwiftUI

// MARK: - Memory Type Content Model

struct MemoryTypeInfo {
    let title: String
    let aboutDescription: String
    let scienceTitle: String
    let scienceBody: String
    let tipsTitle: String
    let tipsBody: String
    let articleTitle: String
    let articleSubtitle: String
    let articleDetailTitle: String
    let articleDetailBody: String
    let secondArticleTitle: String
    let secondArticleSubtitle: String
    let secondArticleDetailTitle: String
    let secondArticleDetailBody: String
    let accentColor: Color
    let iconName: String
    let secondIconName: String

    static func info(for timeFrame: TimeFrame) -> MemoryTypeInfo {
        switch timeFrame {
        case .immediate:
            return MemoryTypeInfo(
                title: "About Immediate Memory",
                aboutDescription:
                    "Immediate memory, also known as working memory, is your ability to hold and manipulate a small amount of information for a very brief period — typically less than 30 seconds.\n\nThis type of memory is crucial for everyday tasks like following a conversation, solving problems, or remembering a phone number just long enough to dial it. Research suggests that most people can hold about 3 to 4 \"chunks\" of information at once.\n\nImmediate memory is one of the first cognitive abilities to show changes in conditions affecting the brain, making it a valuable early indicator of cognitive health.",
                scienceTitle: "The Science Behind It",
                scienceBody:
                    "Immediate memory relies heavily on the prefrontal cortex — the brain's command center for attention and decision-making. When you hold something in your immediate memory, neurons in this region fire in sustained patterns, keeping the information \"active\" while you use it.\n\nUnlike long-term memories that are physically encoded in synaptic connections, immediate memories exist as transient electrical activity. This is why they fade so quickly — once the neural firing stops, the information is lost unless it's consolidated into longer-term storage.\n\nFactors like stress, fatigue, and multitasking can significantly reduce immediate memory capacity, as they compete for the same prefrontal resources.",
                tipsTitle: "How to Improve",
                tipsBody:
                    "• Practice \"chunking\" — group related items together to remember more\n• Minimize distractions during tasks requiring focus\n• Get adequate sleep — it's essential for prefrontal cortex function\n• Engage in regular mental exercises like puzzles or memory games\n• Stay physically active — exercise boosts blood flow to the brain",
                articleTitle: "How Immediate Memory Works",
                articleSubtitle:
                    "Understanding short-term recall and why it matters for daily cognition.",
                articleDetailTitle: "How Immediate Memory Works",
                articleDetailBody:
                    "Immediate memory is your brain's \"scratchpad.\" It allows you to temporarily hold information — like a list of grocery items or the beginning of a sentence someone is speaking — while you actively process it.\n\nYour brain's prefrontal cortex orchestrates this process, maintaining neural firing patterns that represent the information you're holding. This is why distractions can be so disruptive: they interrupt these firing patterns, causing the information to be lost.\n\nThe classic test of immediate memory is digit span — repeating a sequence of numbers forward and backward. Most adults can handle about 7 digits forward (phone number length!) but only about 5 backward, since reversing requires additional mental manipulation.\n\nImmediate memory naturally declines with age, but regular cognitive engagement can help maintain it. Activities that challenge your working memory — like mental arithmetic, learning a musical instrument, or playing strategy games — can help keep these neural circuits sharp.\n\nIn conditions like Alzheimer's disease, immediate memory deficits can appear early, making daily tasks increasingly challenging. Monitoring these changes over time provides valuable insights into cognitive health trajectories.",
                secondArticleTitle: "Why Short-Term Recall Matters",
                secondArticleSubtitle:
                    "The role of working memory in everyday life and cognitive health monitoring.",
                secondArticleDetailTitle: "Why Short-Term Recall Matters",
                secondArticleDetailBody:
                    "Working memory isn't just about remembering things briefly — it's the foundation of nearly everything we do cognitively. Reading comprehension, mental arithmetic, following directions, and even holding a conversation all depend on it.\n\nResearch has shown that working memory capacity is one of the strongest predictors of fluid intelligence — your ability to reason and solve new problems. People with larger working memory capacities tend to perform better on tasks requiring complex thinking.\n\nFor caregivers monitoring a loved one's cognitive health, changes in immediate memory can be among the earliest signs of cognitive decline. Difficulty following multi-step instructions, losing track of conversations, or frequently forgetting what they were about to do can all indicate changes in working memory function.\n\nThe Recap quiz measures immediate memory through tasks that assess your ability to recall recently presented information, giving you a consistent benchmark to track over time.",
                accentColor: .orange,
                iconName: "bolt.fill",
                secondIconName: "brain"
            )

        case .recent:
            return MemoryTypeInfo(
                title: "About Recent Memory",
                aboutDescription:
                    "Recent memory covers your ability to recall events and information from the near past — ranging from hours to days or weeks ago. It bridges the gap between immediate recall and long-term storage.\n\nThis type of memory is central to daily functioning: remembering what you had for breakfast, the details of yesterday's conversation, or where you parked your car. Recent memories are still being consolidated, making them more fragile than older, well-established memories.\n\nDeficits in recent memory are often among the most noticeable early changes in neurodegenerative conditions, which is why tracking it regularly is so important.",
                scienceTitle: "The Science Behind It",
                scienceBody:
                    "Recent memory depends heavily on the hippocampus — a seahorse-shaped structure deep in the temporal lobe. The hippocampus acts as a relay station, binding together the various sensory details of an experience into a coherent memory.\n\nWhen you form a new memory, the hippocampus creates a temporary \"index\" that links together information stored across different brain regions. Over hours and days, through a process called consolidation (which happens largely during sleep), these connections are strengthened, and the memory gradually becomes less dependent on the hippocampus.\n\nThis is why the hippocampus is one of the first brain regions affected in Alzheimer's disease, and why difficulty forming new recent memories is often one of the earliest symptoms.",
                tipsTitle: "How to Improve",
                tipsBody:
                    "• Prioritize quality sleep — memory consolidation is most active during deep sleep\n• Use spaced repetition to reinforce recent memories\n• Create associations and vivid mental images to strengthen encoding\n• Maintain a consistent daily routine to reduce memory load\n• Stay socially engaged — conversation exercises recent memory naturally",
                articleTitle: "Understanding Memory Consolidation",
                articleSubtitle:
                    "How your brain transforms recent experiences into lasting memories during sleep.",
                articleDetailTitle: "Understanding Memory Consolidation",
                articleDetailBody:
                    "Memory consolidation is one of the most fascinating processes in neuroscience. When you experience something, your hippocampus quickly creates a temporary record. But this initial memory trace is fragile and easily disrupted.\n\nDuring sleep — particularly during slow-wave (deep) sleep — your hippocampus \"replays\" the day's experiences to the neocortex, essentially teaching the cortex to store the memory independently. This replay happens at roughly 20 times faster than the original experience.\n\nThis is why a good night's sleep after learning something new dramatically improves retention. Studies have shown that even a short nap can significantly boost memory consolidation compared to staying awake for the same period.\n\nStress hormones like cortisol can interfere with this process, which explains why chronic stress often leads to memory difficulties. The hippocampus is particularly sensitive to cortisol, and prolonged exposure can actually cause it to shrink.\n\nFor individuals at risk of cognitive decline, maintaining healthy sleep patterns and managing stress are two of the most impactful lifestyle interventions for supporting recent memory function.",
                secondArticleTitle: "The Hippocampus and Daily Recall",
                secondArticleSubtitle:
                    "Why recent memories are vulnerable and how to support your brain's memory center.",
                secondArticleDetailTitle: "The Hippocampus and Daily Recall",
                secondArticleDetailBody:
                    "The hippocampus is often called the brain's \"memory gateway.\" No larger than your thumb, this structure is remarkably powerful — and remarkably vulnerable.\n\nEvery time you remember what you did yesterday or recall a recent conversation, your hippocampus is at work, retrieving the neural \"index\" it created when the experience first occurred. This index activates the sensory cortices that originally processed the experience, essentially reconstructing the memory.\n\nInterestingly, memories are not like video recordings. Each time you recall a recent memory, it becomes temporarily unstable and must be re-consolidated. This means memories can be modified each time they're retrieved — a process called reconsolidation.\n\nThe hippocampus is particularly vulnerable to the effects of aging, Alzheimer's disease, and chronic stress. In Alzheimer's disease, the hippocampus is one of the first regions to show pathological changes, which is why difficulty remembering recent events is often the earliest symptom.\n\nRegular cognitive engagement, physical exercise, and a Mediterranean-style diet have all been shown to support hippocampal health and may help maintain recent memory function as we age.",
                accentColor: .blue,
                iconName: "clock.fill",
                secondIconName: "moon.zzz.fill"
            )

        case .remote:
            return MemoryTypeInfo(
                title: "About Remote Memory",
                aboutDescription:
                    "Remote memory is your ability to recall information and events from the distant past — spanning years or even decades. These are the memories that form the chapters of your personal autobiography.\n\nRemote memories include significant life events, childhood experiences, general knowledge you've accumulated over a lifetime, and deeply learned skills. They are among the most resilient types of memory, often remaining intact even when other memory systems begin to decline.\n\nHowever, remote memory is not perfectly preserved — it can gradually fade or be subtly altered over time, and significant changes in remote recall can indicate deeper neurological changes.",
                scienceTitle: "The Science Behind It",
                scienceBody:
                    "Remote memories have undergone extensive consolidation and are stored broadly across the neocortex — the brain's outer layer responsible for higher-order thinking. Unlike recent memories, remote memories are largely independent of the hippocampus.\n\nThis distributed storage is what makes remote memories so resilient. Even when the hippocampus is damaged (as in early Alzheimer's disease), well-established remote memories often remain accessible. This is known as Ribot's law: the observation that newer memories are more susceptible to disruption than older ones.\n\nHowever, remote memories aren't static. Research shows that each retrieval can subtly modify a memory through reconsolidation. The emotional significance of a memory also affects its durability — emotionally charged events are typically remembered more vividly and accurately due to the action of the amygdala during encoding.",
                tipsTitle: "How to Improve",
                tipsBody:
                    "• Engage in reminiscence activities — looking at old photos, revisiting music from the past\n• Tell and retell personal stories — this strengthens remote memory traces\n• Stay intellectually curious — learning new things creates connections with old knowledge\n• Practice gratitude and reflection — emotional engagement reinforces memories\n• Maintain strong social connections — sharing memories keeps them alive",
                articleTitle: "How Memories Stand the Test of Time",
                articleSubtitle:
                    "Understanding why some memories last a lifetime and what long-term recall tells us about brain health.",
                articleDetailTitle: "How Memories Stand the Test of Time",
                articleDetailBody:
                    "The fact that you can remember your childhood home, your first day of school, or a song from decades ago is a testament to the remarkable power of memory consolidation.\n\nOver years of repeated retrieval and reconsolidation, remote memories become deeply embedded in the neocortex's synaptic connections. They transition from hippocampus-dependent traces to distributed cortical representations — essentially becoming part of the brain's structural wiring.\n\nThis is why remote memories show a characteristic pattern in neurological conditions. In Alzheimer's disease, a person may vividly recall events from 40 years ago while struggling to remember what happened yesterday. This temporal gradient (described by Ribot's law) reflects the hippocampal damage that characterizes early Alzheimer's — newer memories that still depend on the hippocampus are lost first.\n\nEmotional memories tend to be especially durable. The amygdala, which processes emotions, enhances memory encoding by signaling the hippocampus to \"pay extra attention\" during emotional events. This is why flashbulb memories — vivid recollections of highly emotional events — can feel as fresh as the day they happened.\n\nTracking remote memory over time can reveal important patterns. While mild difficulty with distant recall is normal with aging, a significant or progressive decline may warrant further evaluation.",
                secondArticleTitle: "Reminiscence and Brain Health",
                secondArticleSubtitle:
                    "How revisiting old memories can strengthen cognitive function and emotional well-being.",
                secondArticleDetailTitle: "Reminiscence and Brain Health",
                secondArticleDetailBody:
                    "Reminiscence therapy — the structured process of reviewing and discussing past experiences — has emerged as a powerful tool for supporting cognitive and emotional health, particularly in individuals with dementia.\n\nWhen you revisit old memories, you activate widespread neural networks across the brain. The visual cortex reconstructs images, the auditory cortex replays sounds, and the emotional centers recreate the feelings associated with the memory. This comprehensive neural activation is essentially a \"workout\" for the brain.\n\nStudies have shown that regular reminiscence can improve mood, reduce feelings of isolation, and even temporarily improve cognitive function in people with dementia. For caregivers, it provides a meaningful way to connect with their loved one, even as other forms of communication become difficult.\n\nThe Recap app leverages this science through both its memory quiz system and its reminiscence features. By regularly engaging with long-term memories through structured recall tasks, users exercise these vital neural pathways.\n\nOld photographs, familiar music, and personal stories are particularly effective triggers for remote memory recall. The multi-sensory nature of these cues helps activate the distributed neural representations that make up remote memories.",
                accentColor: .green,
                iconName: "clock.arrow.circlepath",
                secondIconName: "heart.text.square.fill"
            )
        }
    }
}

// MARK: - About Report Card

struct AboutReportCard: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppConfig.Colors.textPrimary)

            Text(description)
                .font(.system(size: 16, weight: .regular))
                .lineSpacing(5)
                .foregroundColor(AppConfig.Colors.textPrimary.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Learn More Article Card (tappable)

struct LearnMoreArticleCard: View {
    let title: String
    let subtitle: String
    let baseColor: Color
    let iconName: String
    let detailTitle: String
    let detailBody: String

    @State private var showDetail = false

    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: 0) {
                // Gradient Header
                ZStack {
                    LinearGradient(
                        colors: [baseColor.opacity(0.65), baseColor.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Abstract circles
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 150, height: 150)
                        .offset(x: -70, y: -40)

                    Circle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 180, height: 180)
                        .offset(x: 80, y: 60)

                    Image(systemName: iconName)
                        .font(.system(size: 52))
                        .foregroundColor(.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                }
                .frame(height: 170)
                .clipped()

                // Title & Subtitle
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(AppConfig.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppConfig.Colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.regular, in: .rect)
            }
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
        }
        .accessibilityLabel(title)
        .accessibilityHint("Opens the article details")
        .accessibilityInputLabels([title.lowercased(), "article", "learn more"])
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            ArticleDetailSheet(
                title: detailTitle,
                articleBody: detailBody,
                accentColor: baseColor,
                iconName: iconName
            )
        }
    }
}

// MARK: - Article Detail Sheet

struct ArticleDetailSheet: View {
    let title: String
    let articleBody: String
    let accentColor: Color
    let iconName: String

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                AppConfig.Colors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero header
                        ZStack {
                            LinearGradient(
                                colors: [accentColor.opacity(0.6), accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )

                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 200, height: 200)
                                .offset(x: -80, y: -50)

                            Circle()
                                .fill(Color.black.opacity(0.06))
                                .frame(width: 250, height: 250)
                                .offset(x: 100, y: 80)

                            Image(systemName: iconName)
                                .font(.system(size: 64))
                                .foregroundColor(.white.opacity(0.9))
                                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
                        }
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(24)
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // Title
                        Text(title)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppConfig.Colors.textPrimary)
                            .padding(.horizontal, 20)

                        // Body paragraphs
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(articleBody.components(separatedBy: "\n\n"), id: \.self) {
                                paragraph in
                                Text(paragraph)
                                    .font(.system(size: 16, weight: .regular))
                                    .lineSpacing(6)
                                    .foregroundColor(AppConfig.Colors.textPrimary.opacity(0.85))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
//            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("dismiss", systemImage: "xmark"){
                        dismiss()
                    }
                    .tint(accentColor)
                    .symbolEffect(.drawOn.byLayer, options: .nonRepeating)
                    .accessibilityInputLabels(["dismiss", "close", "done"])
                }
            }
        }
    }
}

// MARK: - Expandable Science Section

struct ExpandableScienceCard: View {
    let title: String
    let iconName: String
    let content: String
    let accentColor: Color

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)

                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppConfig.Colors.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppConfig.Colors.textSecondary.opacity(0.5))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Collapses the section" : "Expands the section")
            .accessibilityInputLabels([title.lowercased(), "expand", "details"])

            if isExpanded {
                Divider().padding(.horizontal, 16)

                Text(content)
                    .font(.system(size: 15, weight: .regular))
                    .lineSpacing(5)
                    .foregroundColor(AppConfig.Colors.textPrimary.opacity(0.8))
                    .padding(16)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassEffect(.regular, in: .rect(cornerRadius: AppConfig.UI.cornerRadius))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
