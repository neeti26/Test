module 0x9ecf772b76415f3ea0c8432d8c1d4fea7a5cfe54730cbb9338b4853ed6098d92::LivePollQuiz {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    struct Quiz has key {
        question: vector<u8>,
        correct_answer: u8,
        reward_amount: u64,
        is_active: bool,
        total_participants: u64,
    }

    struct UserProfile has key {
        total_rewards: u64,
        quizzes_answered: u64,
        correct_answers: u64,
    }

    /// Create quiz (creator funds must cover rewards)
    public entry fun create_quiz(
        creator: &signer,
        question: vector<u8>,
        correct_answer: u8,
        reward_amount: u64
    ) {
        let quiz = Quiz {
            question,
            correct_answer,
            reward_amount,
            is_active: true,
            total_participants: 0,
        };
        move_to(creator, quiz);
    }

    /// Answer quiz and get reward
    public entry fun answer_quiz(
        participant: &signer,
        quiz_creator: address,
        user_answer: u8
    ) acquires Quiz, UserProfile {
        let quiz = borrow_global_mut<Quiz>(quiz_creator);

        assert!(quiz.is_active, 1);

        if (!exists<UserProfile>(signer::address_of(participant))) {
            let profile = UserProfile { total_rewards: 0, quizzes_answered: 0, correct_answers: 0 };
            move_to(participant, profile);
        };

        let user_profile = borrow_global_mut<UserProfile>(signer::address_of(participant));
        user_profile.quizzes_answered = user_profile.quizzes_answered + 1;
        quiz.total_participants = quiz.total_participants + 1;

        if (user_answer == quiz.correct_answer) {
            user_profile.correct_answers = user_profile.correct_answers + 1;
            user_profile.total_rewards = user_profile.total_rewards + quiz.reward_amount;

            // 💡 FIX: transfer reward from quiz creator to participant
            let reward = coin::withdraw<AptosCoin>(&signer::borrow_global_mut<CoinStore<AptosCoin>>(quiz_creator).coin, quiz.reward_amount);
            coin::deposit<AptosCoin>(signer::address_of(participant), reward);
        };
    }
}