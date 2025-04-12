using UnityEngine;

/// <summary>
/// Handles player movement including walking, running and jumping
/// </summary>
[RequireComponent(typeof(Rigidbody))]
public class PlayerMovement : MonoBehaviour
{
    // Movement speed values
    [Header("Movement Settings")]
    [Tooltip("The player's regular movement speed")]
    public float moveSpeed = 5f;
    
    [Tooltip("Multiplier applied when running")]
    public float runSpeedMultiplier = 1.5f;
    
    [Tooltip("Force applied when jumping")]
    public float jumpForce = 7f;
    
    [Header("Ground Detection")]
    [Tooltip("Layer mask for ground detection")]
    public LayerMask groundMask;
    
    [Tooltip("Distance to check for ground")]
    public float groundCheckDistance = 0.2f;
    
    // Component references
    private Rigidbody rb;
    private bool isGrounded = false;
    
    // Initialization
    void Start()
    {
        // Get required component references
        rb = GetComponent<Rigidbody>();
        
        // Verify Rigidbody exists
        if (rb == null)
        {
            Debug.LogError("Rigidbody component is required but not found on " + gameObject.name);
        }
    }
    
    // Physics update
    void FixedUpdate()
    {
        // Check if player is on the ground
        CheckGrounded();
        
        // Handle movement
        HandleMovement();
    }
    
    // Input update
    void Update()
    {
        // Handle jumping
        HandleJumping();
    }
    
    /// <summary>
    /// Checks if the player is grounded using a raycast
    /// </summary>
    void CheckGrounded()
    {
        isGrounded = Physics.Raycast(transform.position, Vector3.down, groundCheckDistance, groundMask);
    }
    
    /// <summary>
    /// Handles player movement based on input axes
    /// </summary>
    void HandleMovement()
    {
        // Get input values
        float horizontalInput = Input.GetAxis("Horizontal");
        float verticalInput = Input.GetAxis("Vertical");
        
        // Calculate movement direction
        Vector3 movement = new Vector3(horizontalInput, 0f, verticalInput).normalized;
        
        // If we have input
        if (movement.magnitude > 0.1f)
        {
            // Check if running (Shift key)
            float currentSpeed = Input.GetKey(KeyCode.LeftShift) ? moveSpeed * runSpeedMultiplier : moveSpeed;
            
            // Apply movement
            Vector3 moveVelocity = movement * currentSpeed;
            
            // Preserve existing Y velocity (gravity/jumping)
            moveVelocity.y = rb.linearVelocity.y;
            
            // Apply the velocity
            rb.linearVelocity = moveVelocity;
            
            // Make player face movement direction
            if (movement != Vector3.zero)
            {
                transform.forward = movement;
            }
        }
        else
        {
            // No horizontal movement, preserve vertical velocity only
            rb.linearVelocity = new Vector3(0f, rb.linearVelocity.y, 0f);
        }
    }
    
    /// <summary>
    /// Handles jumping when spacebar is pressed and player is grounded
    /// </summary>
    void HandleJumping()
    {
        // If player presses space and is grounded
        if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        {
            // Apply jump force
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
        }
    }
    
    // Visual debugging
    void OnDrawGizmosSelected()
    {
        // Visualize ground check
        Gizmos.color = isGrounded ? Color.green : Color.red;
        Gizmos.DrawLine(transform.position, transform.position + Vector3.down * groundCheckDistance);
    }
}
