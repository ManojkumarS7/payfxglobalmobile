<?php
// Add this method to your DeliveryMethodController

public function updateDeliveryMethod(Request $request, $recipientId)
{
    $request->validate([
        'customer_id'      => 'required|exists:customer,id',
        'transaction_id'   => 'required|exists:transactions,id',
        
        'name'             => 'required|string|max:255',
        'delivery_method'  => 'required|in:bank,upi,card',
        'reason_id'        => 'required|integer',

        'mobile'           => 'nullable|string|max:20',
        'phone_code'       => 'nullable|string|max:10',
        'education_loan'   => 'nullable|in:1,2',

        'relationship'     => 'nullable|string|max:50',
        'address'          => 'nullable|string|max:255',
        'country_id'       => 'nullable|exists:countries,id',
        'email'            => 'nullable|email',

        'upi_id'           => 'nullable|string|max:50',

        'bank_name'        => 'nullable|string|max:255',
        'account_number'   => 'nullable|string|max:50',
        'swift_code'       => 'nullable|string|max:50',

        'card_name'        => 'nullable|string|max:255',
        'card_no'          => 'nullable|string|max:50',
        'expiry_date'      => 'nullable|date',

        'routing_number'   => 'nullable|string|max:50',
        'transit_number'   => 'nullable|string|max:50',
        'bsb_code'         => 'nullable|string|max:50',
        'iban'             => 'nullable|string|max:50',
        'sort_code'        => 'nullable|string|max:10',
        'mobile_number'    => 'nullable|string|max:20',
        'bank_address'     => 'nullable|string|max:255',
    ]);

    DB::beginTransaction();

    try {
        // Find the delivery method record to update
        $delivery = DeliveryMethodDetail::where('id', $recipientId)
            ->where('signin_id', $request->customer_id)
            ->firstOrFail();

        // Verify ownership and transaction
        $transaction = Transaction::findOrFail($request->transaction_id);
        
        if ($delivery->transaction_id != $transaction->id) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: Transaction mismatch'
            ], 403);
        }

        // Prepare update data
        $updateData = [
            'name'               => $request->name,
            'delivery_method'    => $request->delivery_method,
            'reason'             => $request->reason_id,  // Note: store uses 'reason', Flutter sends 'reason_id'

            'relationship'       => $request->relationship,
            'address'            => $request->address,
            'country_id'         => $request->country_id,
            'email'              => $request->email,

            'bank_name'          => $request->bank_name,
            'bank_account'       => $request->account_number,
            'swift_code'         => $request->swift_code,
            'ifsc'               => $request->swift_code,

            'upi_id'             => $request->upi_id,

            'card_name'          => $request->card_name,
            'card_no'            => $request->card_no,
            'expiry_date'        => $request->expiry_date,

            'routing_number'     => $request->routing_number,
            'transit_number'     => $request->transit_number,
            'bsb_code'           => $request->bsb_code,
            'iban'               => $request->iban,
            'uk_sort_code'       => $request->sort_code,

            'education_loan'     => $request->education_loan,
            'full_mobile'        => $request->mobile,
            'bank_mobile'        => $request->mobile_number,
        ];

        // Update the delivery method
        $delivery->update($updateData);

        // Handle file uploads (only if files are provided)
        $allowedFileColumns = [
            'Passport_doc',
            'Visa_doc',
            'university_offer_doc',
            'rental_doc',
            'medical_expenses_doc',
            'doct_prescription',
            'admission_letter',
            'ticket_copy',
            'bank_statement',
            'proof_of_funds',
            'invitation_copy',
            'authority_copy',
            'invoice_copy',
            'registration_form',
            'supporting_doc',
            'sanction_letter',
        ];

        foreach ($request->allFiles() as $key => $file) {
            // Skip unknown columns
            if (!in_array($key, $allowedFileColumns)) {
                continue;
            }

            // Delete old file if it exists
            if ($delivery->{$key} && \Storage::disk('public')->exists($delivery->{$key})) {
                \Storage::disk('public')->delete($delivery->{$key});
            }

            // Upload new file
            $path = $file->storeAs(
                'uploads/delivery_docs',
                time().'_'.$key.'.'.$file->getClientOriginalExtension(),
                'public'
            );

            $delivery->{$key} = $path;
        }

        $delivery->save();

        DB::commit();

        // Get transaction data for response
        $transaction = Transaction::findOrFail($request->transaction_id);

        return response()->json([
            'success' => true,
            'message' => 'Delivery method updated successfully',
            'data' => [
                'recipient_id'       => $delivery->id,
                'customer_id'        => $request->customer_id,
                'user_id'            => $request->customer_id,
                'transaction_id'     => $transaction->id,
                'transaction_code'   => $transaction->transaction_code ?? '',
                'name'               => $delivery->name,
                'delivery_method'    => $delivery->delivery_method,
                'email'              => $delivery->email ?? '',
                'send_amount'        => $transaction->send_amount ?? 0,
                'recipient_amount'   => $transaction->recipient_amount ?? 0,
                'currency'           => $transaction->destination_currency ?? 'USD',
                'exchange_rate'      => $transaction->exchange_rate ?? 1,
            ]
        ], 200);

    } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
        DB::rollBack();
        return response()->json([
            'success' => false,
            'message' => 'Delivery method record not found'
        ], 404);
    } catch (\Throwable $e) {
        DB::rollBack();
        \Log::error('Update Delivery Method Error: ' . $e->getMessage());
        return response()->json([
            'success' => false,
            'message' => 'Server error',
            'error'   => $e->getMessage(),
        ], 500);
    }
}

// Add this route to your routes file:
// Route::post('app/customer/delivery-method/{recipientId}', [DeliveryMethodController::class, 'updateDeliveryMethod']);
