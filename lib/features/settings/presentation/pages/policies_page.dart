import 'package:flutter/material.dart';
import '../../../../core/constants/colors.dart';

class Policies extends StatelessWidget {
  const Policies({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : AppColors.authColor,
    );
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.primaryColor,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      height: 1.5,
      color: isDarkMode ? Colors.white : AppColors.black,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Policies',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome to VANDACOO", style: titleStyle),
            const SizedBox(height: 8),
            Text(
              "At VANDACOO, we believe in the power of connection. Our platform serves as a vibrant hub where individuals from diverse backgrounds unite to explore, learn, and share their passion and talent. From sports enthusiasts to tech innovators, from foodies to aspiring entrepreneurs, VANDACOO is where you belong.",
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            Center(child: Text("MISSION", style: sectionTitleStyle)),
            const SizedBox(height: 8),
            Text(
              "VANDACOO is committed to fostering a community-driven space where individuals can discover, connect, and grow. Our mission is to empower our users to pursue their interests, expand their horizons, and make meaningful connections with like-minded individuals.",
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),
            Center(
                child: Text("COMMUNITY GUIDELINES", style: sectionTitleStyle)),
            const SizedBox(height: 8),
            _buildBullet(
                "RESPECTFUL INTERACTION",
                "Uphold VANDACOO'S values of respect and inclusivity in all interactions. Treat fellow members with kindness and consideration, fostering a supportive environment where everyone feels valued.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "PASSION AND PURPOSE",
                "Engage in discussions and share content that aligns with VANDACOO'S diverse themes, including sports, education, entertainment, health, kids, technology, finance and food & travel.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "ZERO TOLERANCE FOR HATE",
                "VANDACOO has a zero-tolerance policy for hate speech, harassment, bullying or any form of discrimination. Such behaviour undermines the sense of community we strive to create and will not be tolerated.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "PROTECT PRIVACY AND SAFETY",
                "Safeguard your own and others privacy. Avoid sharing personal information and ensure the safety of all community members by refraining from engaging in harmful activities.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "PROMOTE QUALITY CONTENT",
                "Share content that is accurate, informative, and adds value to the community. Help maintain the integrity of VANDACOO by contributing thoughtfully and respectfully to discussions.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "NO SPAM",
                "Keep VANDACOO free from spam, unsolicited advertisements, or promotion unrelated to the app's themes. Respect the community's focus and refrain from engaging in disruptive or irrelevant activities.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "CHILD-FRIENDLY ENVIRONMENT",
                "Maintain a safe and appropriate environment for users of all ages, especially children. Refrain from sharing content or engaging in discussions that may be unsuitable for minors.",
                bodyStyle,
                isDarkMode),
            _buildBullet(
                "EMPOWERMENT THROUGH REPORTING",
                "Empower the community by reporting any violations of these guidelines to our moderation team. Your vigilance helps us uphold the standards of VANDACOO and ensures a positive experience for all users. By adhering to these guidelines, together, we can cultivate a vibrant and enriching community on VANDACOO, where passion meets purpose and connections flourish.",
                bodyStyle,
                isDarkMode),
            const SizedBox(height: 24),
            Center(
              child: Text("CONSEQUENCES OF BREAKING GUIDELINES",
                  style: sectionTitleStyle),
            ),
            const SizedBox(height: 8),
            _buildNumbered(
                "1. WARNING SYSTEM",
                "Upon the first violation of the community guidelines, a warning will be issued to the user, outlining the specific violation, and reminding them of the expected conduct within the community.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "2. TEMPORARY SUSPENSION",
                "For repeated violations or more severe breaches of the guidelines, temporary suspension of the user's account may be imposed. The duration of the suspension will be determined based on the severity of the violation.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "3. PERMANENT BAN",
                "In cases of egregious violations, such as hate speech, harassment or repeated disregard for the community guidelines, the user may be permanently banned from the community. This action is reserved for situations where the user's behaviour poses a significant threat to the safety and well-being of other members.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "4. CONTENT REMOVAL",
                "Any content that violates the guidelines will be promptly removed from the platform. This includes posts, comments, or other contributions that are deemed inappropriate, offensive, or harmful to the community.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "5. APPEAL PROCESS",
                "Users who believe their account was penalized unfairly may appeal the decision through a designated process. The moderation team will review the appeal and reconsider the action taken, if deemed necessary.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "6. EDUCATIONAL RESOURCES",
                "Alongside penalties, users may be provided with educational resources or guidance on how to adhere to the community guidelines in the future. This may include links to relevant policies, articles on online etiquette, or tips for fostering positive interactions within the community.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "7. COMMUNITY SERVICE",
                "In certain cases, users may be given the opportunity to perform community service tasks as a means of rectifying their behaviour and demonstrating a commitment to the community's values. These tasks could include creating educational content or assisting with community outreach efforts.",
                bodyStyle,
                isDarkMode),
            _buildNumbered(
                "8. CONTINUOUS MONITORING",
                "The moderation team will continue to monitor user behaviour to ensure ongoing compliance with the guidelines. Users who demonstrate a pattern of improvement may have previous penalties reconsidered, while those who persist in violating the guidelines will face escalating consequences.",
                bodyStyle,
                isDarkMode),
            const SizedBox(height: 24),
            Text(
              "By enforcing these consequences consistently and transparently, we at VANDACOO aim to maintain a safe respectful, and welcoming environment for all members of the community.",
              style: bodyStyle,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBullet(
      String title, String description, TextStyle? style, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(description,
              style: style?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87),
              textAlign: TextAlign.justify),
        ],
      ),
    );
  }

  Widget _buildNumbered(
      String title, String description, TextStyle? style, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(description,
              style: style?.copyWith(
                  color: isDarkMode ? Colors.white : Colors.black87),
              textAlign: TextAlign.justify),
        ],
      ),
    );
  }
}
